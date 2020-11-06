---
summary: How to install and basic config for incremental banning...
---

# Install with incremental bans!

Install with: `sudo apt install fail2ban`
Then open the file `/etc/fail2ban/jail.d/custom.conf` and insert:
```ini
[DEFAULT]
# "bantime.increment" allows to use database for searching of previously banned ip's to increase a
# default ban time using special formula, default it is banTime * 1, 2, 4, 8, 16, 32...
bantime.increment = true

# "bantime.rndtime" is the max number of seconds using for mixing with random time
# to prevent "clever" botnets calculate exact time IP can be unbanned again:
bantime.rndtime = 2048

# following example can be used for small initial ban time (bantime=60) - it grows more aggressive at begin,
# for bantime=60 the multipliers are minutes and equal: 1 min, 5 min, 30 min, 1 hour, 5 hour, 12 hour, 1 day, 2 day
bantime.multipliers = 1 5 30 60 300 720 1440 2880
```
Then watch `/var/log/fail2ban.log` while all the bad guys get banned...

## Note
When you restart a docker container, you also MUST restart fail2ban - otherwise the old ban times must first expire, until they will again be blocked effectively!
