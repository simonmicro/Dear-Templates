---
summary: Enable aggressive unattended upgrades on Ubuntu and Debian
---

# Install #
```bash
sudo apt install unattended-upgrades apt-listchanges
```

# Config

## Mails
In `/etc/apt/apt.conf.d/50unattended-upgrades` uncomment:
```
Unattended-Upgrade::Mail "root";
```
...to allow a regulary report about the updates.

## More aggressive!
You also may modify the `Unattended-Upgrade::Allowed-Origins` array to only include a...
```
    "origin=${distro_id}";
```
...this will allow automatic updates for basically _all_ packages - make sure to have backups!

## Auto cleanups & more
Well, just uncomment & modify these in the config (I just recommend this settings):
```
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
```

## Automatic reboots
Also when you are configuring this on an e.g. containerized environment or webserver (basically everything except of root-/gameservers), you may also want to enable automatic reboots (uncomment & modify these):
```
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
```

# Testing
Test with (check for the matching string messages!!!):
```bash
sudo unattended-upgrade --debug --dry-run
```

# Activate it
Contradictionary to the name "unattended-upgrades", the package is NOT active by default! You have to run those commands to really enable unattended upgrades:
```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```
Or if you are too lazy to select "Yes" - run this non-interactive:
```bash
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive unattended-upgrades
```
