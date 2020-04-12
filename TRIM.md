---
title: TRIM
summary: Enable automatic TRIM on debian
type: blog
banner: "/img/dear-templates/default.jpg"
---

**First line is not needed on Debian Buster anymore!**
```
sudo cp /usr/share/doc/util-linux/examples/fstrim.{service,timer} /etc/systemd/system`
sudo systemctl enable fstrim.timer`
sudo systemctl start fstrim.timer
```
