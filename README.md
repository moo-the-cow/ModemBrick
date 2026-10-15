**execute initial setup (1-time only)**

```
curl -sSL "https://raw.githubusercontent.com/moo-the-cow/ModemBrick/refs/heads/main/initial-setup.sh" | sudo bash
```

**fetch update file** (usually by the app but feel free to trigger yourself any time)

```
curl -fsSL "https://raw.githubusercontent.com/moo-the-cow/ModemBrick/refs/heads/main/update.sh" -o /opt/ModemBrick/update.sh && chmod +x /opt/ModemBrick/update.sh && sudo /opt/ModemBrick/update.sh "https://github.com/moo-the-cow/ModemBrick/raw/refs/heads/main/ModemBrick.tar.gz"
```


after the 2-step setup you can access it via http://modembrick.local right away
