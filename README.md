**execute initial setup (1-time only)

```
curl -sSL "https://github.com/moo-the-cow/ModemBrick/raw/refs/heads/main/inital-setup.sh" | sudo bash
```

fetch update file

```
curl -fsSL "https://github.com/moo-the-cow/ModemBrick/raw/refs/heads/main/update.sh" -o /opt/ModemBrick/update.sh && chmod +x /opt/ModemBrick/update.sh
```
