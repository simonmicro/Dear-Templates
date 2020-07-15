---
summary: Move any application windows as icon into the tray
---

For this use `kdocker` - install it from apt...

Command for e.g. Thunderbird would be (with 20 seconds wait for the window - good for HDD based systems):
```bash
kdocker -q -i /usr/share/icons/Papirus-Dark/48x48/apps/thunderbird.svg -d 20 thunderbird
```
If you the above to the startup, you now have a good email program always in background available!
