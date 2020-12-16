---
summary: How to increase the read speed of disks normally (eject) and with special tools (cdvdcontrol)
---

For most drives the following will work (make sure to switch to "Performance Mode" in the BIOS, when using a Thinkpad):
```bash
eject -vx 0
```
-> `0` disables any limit - you could also enter a speed (to test it is working choose something like `8` and the disk should spin down).

But as always: Some disks drives (PIONEER) won't respect that and their firmware needs a kick in the b*** -> run (package `qpxtool`):
```bash
cdvdcontrol -d /dev/sr0 --pio-limit off --pio-quiet perf
```
To disable any noise limits (take a look into the manual to revert that, as it is very bad during watching movies)!
