---
summary: Fast and dirty way to enable vnc on a debian server
---

# Install #
```bash
sudo apt install vnc4server openbox-lxde-session
```

# Start #
```bash
vncserver -localhost no -geometry 1920x1080 -geometry 1366x768
```
