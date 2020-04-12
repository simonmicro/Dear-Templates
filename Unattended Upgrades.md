---
title: Unattended Upgrades
summary: Enable aggresive unattended upgrades on debian
type: blog
banner: "/img/dear-templates/default.jpg"
---

`sudo apt install unattended-upgrades apt-listchanges`

`sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`

Update:
```
//Unattended-Upgrade::Mail "root";
```
->
```
Unattended-Upgrade::Mail "root";
```
(MAYBE REMOVE THE label...security PART OF THE STRING, so ALL updates will be installed)

`sudo dpkg-reconfigure -plow unattended-upgrades`

Test with (check for the matching string messages!!!): `sudo unattended-upgrade -d`
