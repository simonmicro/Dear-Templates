---
title: Find - Temp folders
summary: Little command to create auto-cleaning folders
type: blog
banner: "/img/dear-templates/default.jpg"
---

# Every file/folder older than 48h will be deleted... #
Add following to the (roots-)crontab: `@daily find "[TARGET_FOLDER]" -mindepth 1 -mtime +1 -delete >/dev/null 2>&1`
