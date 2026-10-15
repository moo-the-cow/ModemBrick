## RECOMMENDATION
it is advised to enable onboard wifi if it is available for your board (like raspberry pi4)

if you have exited the setup already you can always get back there via

`dietpi-config`

Go To "7 Network Options: Adapters" to make sure to activate it
<img width="1180" height="469" alt="image" src="https://github.com/user-attachments/assets/14796bd4-53d6-4ec7-b19d-949fd66c6b06" />



**execute initial setup (1-time only)**

```
curl -sSL "https://raw.githubusercontent.com/moo-the-cow/ModemBrick/refs/heads/main/initial-setup.sh" | sudo bash
```

**fetch update file** (usually by the app but feel free to trigger yourself any time)

```
curl -fsSL "https://raw.githubusercontent.com/moo-the-cow/ModemBrick/refs/heads/main/update.sh" -o /opt/ModemBrick/update.sh && chmod +x /opt/ModemBrick/update.sh && sudo /opt/ModemBrick/update.sh "https://github.com/moo-the-cow/ModemBrick/raw/refs/heads/main/ModemBrick.tar.gz"
```


after the 2-step setup you can access it via http://modembrick.local right away
