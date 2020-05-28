---
summary: Three commands to enable automatic TRIM on debian
---

**First line is not needed on Debian Buster anymore!**
```
sudo cp /usr/share/doc/util-linux/examples/fstrim.{service,timer} /etc/systemd/system`
sudo systemctl enable fstrim.timer`
sudo systemctl start fstrim.timer
```
