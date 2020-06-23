---
summary: Enable aggressive unattended upgrades on Ubuntu and Debian
---

# Install #
```bash
sudo apt install unattended-upgrades apt-listchanges
```

# Config #
In `/etc/apt/apt.conf.d/50unattended-upgrades` uncomment:
```
//Unattended-Upgrade::Mail "root";
```
...to allow a regulray report about the updates. Also may change the `Unattended-Upgrade::Allowed-Origins` array to include a `"*:*";` - this will allow automatic updates for _all_ packages!

Test with (check for the matching string messages!!!): `sudo unattended-upgrade --debug --dry-run`
