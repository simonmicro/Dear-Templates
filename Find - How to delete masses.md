---
summary: A little command to create self-cleaning folders and how to clean up after Nextcloud
---

# Every file/folder older than 48h will be deleted... #
Add following to the (roots-)crontab: `@daily find "[TARGET_FOLDER]" -mindepth 1 -mtime +1 -delete >/dev/null 2>&1`

# How to clean the `.~` files of Nextcloud #
First locate and make sure they are not important...
```bash
find ./ -name '*.~*'
```

Then delete them...
```bash
find ./ -name '*.~*' -exec rm -rf {} \;
```
