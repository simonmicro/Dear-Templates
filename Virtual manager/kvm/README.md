# HowTo
Just add a new mapped shared folder with a new [TARGET_PATH].
To mount it, just insert following line into the guests `/etc/fstab`:
```
[TARGET_PATH]    [LOCAL_PATH]       9p      trans=virtio,version=9p2000.L    0       0
```
IF you get emergency boot failures - insert the following into `/etc/initramfs-tools/modules`:
```
9p
9pnet
9pnet_virtio
```
...and update `sudo update-initramfs -u`!
