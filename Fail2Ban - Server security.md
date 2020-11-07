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

# Docker

When you want to use fail2ban with Docker you MUST use an other approach: Because the default way for the `docker-action.conf` is to create an own chain and insert the blocking rules there. This is fine when you are using normal
applications - but Docker will may or may not recreate its rules on its own. This causes your fail2bain rules to shift down in the hierarchy and therefore will get ignored. You can test that by simply restarting your container and then
watching the efficiency of your newly installed fail2ban rules: They'll get ignored. To make that all work you have to use an other `docker-action.conf` like this:

```ini
[Definition]
actioncheck = iptables -n -L DOCKER-USER | grep -q 'DOCKER-USER[ \t]'

actionban = iptables -I DOCKER-USER -s <ip> -j DROP

actionunban = iptables -D DOCKER-USER -s <ip> -j DROP
```

As you may note there are no `actionstart` and `actionstop` - as we now use the iptables chain `DOCKER-USER`, which is specially designed to be used for stuff like this! This chain is guaranteed to be evaluated _before_ any further internal
networking for Docker. When you fail to do this you will may note that your rukes are ignored randomly or when you restart your containers!
