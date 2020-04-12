---
title: RAID
summary: RAID using mdadm - predecessor of ZFS RAID
type: blog
banner: "/img/dear-templates/default.jpg"
---

# Setup #
`sudo apt install mdadm`

# Activate RAID5 on three disks #
`mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sda1 /dev/sdb1 /dev/sdc1`

# mdadm state #
`cat /proc/mdstat`
`mdadm --detail /dev/md0`

# Check a RAID for its state #
_insert any of its devices_
`sudo mdadm -E /dev/sda1`

# Add it to the fstab #
/dev/md/0    /mnt/raid_01    ext4    defaults    0   0
...or use its uuid...

# And append it to the config... #
`sudo mdadm --detail --scan >> /etc/mdadm/mdadm.conf`
_Results is_ `ARRAY /dev/md/0 metadata=1.2 name=server:0 UUID=xxxxxxxx:xxxxxxxx:xxxxxxxx:xxxxxxxx`

# Add a spare drive #
`mdadm --add /dev/md/0 /dev/sdd1`

# (Re-)Add an old member drive #
`mdadm --re-add /dev/md/0 /dev/sdd1`

# Remove an member drive #
1. Mark it as failing (or it already has an (F) in mdstat)
    `mdadm --fail /dev/md/0 /dev/sdd1`
2. Remove it...
    `mdadm --remove /dev/md/0 /dev/sdd1`
