#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)."
  exit 1
fi

echo "==> Configuring Hostname and Local Domains..."
# 1. Set hostname to ModemBrick
hostnamectl set-hostname ModemBrick
echo "ModemBrick" > /etc/hostname

# 2. Configure /etc/hosts safely
if ! grep -q "ModemBrick" /etc/hosts; then
  # Append mapping for 127.0.0.1
  sed -i '/127.0.0.1\s*localhost/s/$/ ModemBrick/' /etc/hosts
  echo "127.0.0.1 ModemBrick.local" >> /etc/hosts
fi

echo "==> Preparing System and Non-Interactive Environment..."
# Make apt completely automatic and quiet
export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Core Apt Packages..."
apt-get update -y
apt-get install -y --no-install-recommends \
  modemmanager \
  curl \
  libicu-dev \
  zlib1g \
  nginx \
  avahi-daemon \
  libnss-mdns \
  network-manager \
  openssh-server \
  xz-utils \
  rfkill \
  libqmi-utils

echo "==> Installing .NET 10 Runtimes to /opt/dotnet..."
# Create directory beforehand
mkdir -p /opt/dotnet

# Install .NET 10 Runtime
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 10.0 --runtime dotnet --install-dir /opt/dotnet --no-path
# Install ASP.NET Core 10 Runtime
curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 10.0 --runtime aspnetcore --install-dir /opt/dotnet --no-path

# Create binary symlink safely
if [ -L /usr/bin/dotnet ] || [ -f /usr/bin/dotnet ]; then
  rm -f /usr/bin/dotnet
fi
ln -s /opt/dotnet/dotnet /usr/bin/dotnet

# Set environment variables for the root user and dietpi user profiles
echo 'export DOTNET_ROOT=/opt/dotnet' >> /root/.bashrc
if [ -d /home/dietpi ]; then
  echo 'export DOTNET_ROOT=/opt/dotnet' >> /home/dietpi/.bashrc
fi

echo "==> Customizing NetworkManager for DietPi Cellular configuration..."
# Remove default static interface file if it exists to let NetworkManager handle it
if [ -f /etc/network/interfaces.d/eth0.conf ]; then
  rm -f /etc/network/interfaces.d/eth0.conf
fi

# Ensure NetworkManager manages local interfaces and uses permanent MAC addresses
NM_CONF="/etc/NetworkManager/NetworkManager.conf"
if [ -f "$NM_CONF" ]; then
  sed -i 's/managed=false/managed=true/g' "$NM_CONF"
else
  mkdir -p /etc/NetworkManager
  cat <<EOF > "$NM_CONF"
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true
EOF
fi

# Append MAC address randomization overrides to prevent spoofing
cat <<EOF >> "$NM_CONF"

[device]
wifi.scan-rand-mac-address=no

[connection]
wifi.cloned-mac-address=permanent
EOF

# Enable and start NetworkManager immediately
systemd-run --property=Description="Initial NetworkManager invocation" systemctl enable --now NetworkManager

echo "==> Configuring Nginx Reverse Proxy for ModemBrick.local..."
# Create the Nginx server block to route ModemBrick.local to the Kestrel .NET app (Port 5000)
cat <<'EOF' > /etc/nginx/sites-available/modembrick
# 1. Add this map block BEFORE your server block (e.g., at the top of the file)
# It dynamically sets the Connection header based on what the client requested.
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen        80;
    listen        [::]:80;
    server_name   modembrick.local www.modembrick.local modembrick;

    location / {
        # Note: Trailing slash removed from proxy_pass to preserve full SignalR hub URLs
        proxy_pass         http://127.0.0.1:5000; 
        
        proxy_http_version 1.1;
        
        # This preserves the 'Upgrade' header from the client browser
        proxy_set_header   Upgrade $http_upgrade;
        
        # This maps the dynamic variable we declared above ($connection_upgrade)
        proxy_set_header   Connection $connection_upgrade;
        
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        
        # Optional: Prevents Nginx from dropping silent/idle SignalR connections prematurely
        proxy_read_timeout 100s;
        proxy_send_timeout 100s;
    }
}
EOF

# Enable the block and remove default if present
ln -sf /etc/nginx/sites-available/modembrick /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Restart Nginx to apply changes
systemctl restart nginx

echo "==> Generating Systemd Service File..."
# Create the managed service file requested
cat <<'EOF' > /etc/systemd/system/modembrick.service
[Unit]
Description=ModemBrick service
After=network.target

[Service]
Environment="BOARDNAME=raspberrypi4"
WorkingDirectory=/opt/ModemBrick
ExecStart=/opt/dotnet/dotnet /opt/ModemBrick/ModemBrick.dll --urls "http://[::]:5000" --environment Production
KillMode=process
Restart=always
# amount of time to wait before restarting the service
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload daemon to index the new service, then enable it
systemctl daemon-reload
systemctl enable modembrick.service

echo "==> Creating directories and fixing permissions..."
# Ensure the working folder exists so service doesn't crash on start if binary isn't dropped yet
mkdir -p /opt/ModemBrick

# Set user ownership of /opt recursively to dietpi:dietpi
if id "dietpi" &>/dev/null; then
  chown -R dietpi:dietpi /opt
else
  echo "Warning: user 'dietpi' does not exist on this environment. Skipping recursive chown."
fi

echo "===================================================="
echo " Setup complete! Hostname is now ModemBrick."
echo " Reconnect your terminal or run: source ~/.bashrc"
echo " Place your ModemBrick app files into /opt/ModemBrick/"
echo " Start your application using: sudo systemctl start modembrick"
echo "===================================================="
