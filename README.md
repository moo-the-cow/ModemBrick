**execute initial setup (1-time only)

```
curl -sSL "https://raw.githubusercontent.com/moo-the-cow/ModemBrick/refs/heads/main/initial-setup.sh" | sudo bash
```

fetch update file

```
curl -fsSL "https://raw.githubusercontent.com/moo-the-cow/ModemBrick/refs/heads/main/update.sh" -o /opt/ModemBrick/update.sh && chmod +x /opt/ModemBrick/update.sh && sh /opt/ModemBrick/update.sh
```
