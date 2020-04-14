---
title: Apcupsd - UPS monitoring
summary: HowTo get a weekly UPS status report
type: blog
banner: "/img/dear-templates/ups.jpg"
---

# Weekly UPS report... #
...add this to crontab:
```
@weekly /sbin/apcaccess
```
...if email is configured, you'll receive now regulary updates. Sort them with Sieve and be happy!
