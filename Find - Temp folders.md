---
summary: A little command to create self-cleaning folders
---

# Every file/folder older than 48h will be deleted... #
Add following to the (roots-)crontab: `@daily find "[TARGET_FOLDER]" -mindepth 1 -mtime +1 -delete >/dev/null 2>&1`
