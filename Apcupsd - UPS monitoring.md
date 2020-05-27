---
summary: HowTo get a weekly UPS status report
---

# Weekly UPS report... #
...add this to crontab:
```
@weekly /sbin/apcaccess
```
...if email is configured, you'll receive now regulary updates. Sort them with Sieve and be happy!
