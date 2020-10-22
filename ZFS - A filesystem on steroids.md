---
summary: Install, usage, tips and tricks, encryption, compression & more!
---

# Setup on Debian (10) #
1. Add the "contib" and "non-free" branch to the `/etc/apt/sources.list`
2. Install zfs: `sudo apt install zfsutils-linux`
3. Reboot or modprobe (`sudo modprobe zfs`) to activate zfs

# Under Debian 10: Upgrade to zfs 0.8+ #
...otherwise the encryption won't be there.
Add `deb http://deb.debian.org/debian buster-backports main` to the sources.list and run `sudo apt update`...

# Create a pool #
Create (for device use: _/dev/disk/by-id/..._, **APPEND `-o ashift=12` IF THE DEVICE IS A REAL DISK**):
```bash
sudo zpool create [ZFS_POOL] [DEVICE/FILE]
```

Oh, I see - you want encryption (a SUBPOOL is recommended - do not encrypt the root one, so you can't creaty any unencrypted anymore...)?
You have to create a key and then tell zfs to use it ([take a note](https://www.reddit.com/r/zfs/comments/bnvdco/zol_080_encryption_dont_encrypt_the_pool_root/)):
```bash
openssl rand -hex -out /root/keys/key 32
zfs create -o encryption=on -o keyformat=hex -o keylocation=file:///root/keys/key [ZFS_POOL]
```
_For following you can use `-O` at `zpool` to pass options to `zfs`, otherwise `-o` is at any `zfs` command just enough._
And RAID? Of course RAID5 - here some commands (omit the `raidz` part to create a somewhat dangerous RAID0)!
* Create: `sudo zpool create -f [ZFS_POOL] raidz [DEVICE/FILE] [DEVICE/FILE] [DEVICE/FILE]` <- **Add won't work here!**
* Replace: `sudo zpool replace [ZFS_POOL] [DEVICE/FILE] [DEVICE/FILE]`
* Detach the failed: `sudo zpool detach [ZFS_POOL] [DEVICE/FILE]` <- **Maybe offlining first**

# Load all the encryption keys at startup #
Add the service: `/etc/systemd/system/zfs-load-all-keys.service`
```systemd
[Unit]
Description=Loads all ZFS keys for all imported pools
DefaultDependencies=no
Before=zfs-mount.service
After=zfs-import.target
Requires=zfs-import.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/zfs load-key -a

[Install]
WantedBy=zfs-mount.service
```
# Onlining and offlining devices in a pool #
* `sudo zpool offline [ZFS_POOL] [DEVICE/FILE]`
* `sudo zpool online [ZFS_POOL] [DEVICE/FILE]`

# Get usage of all pools #
`sudo zpool list`

# Delete a pool #
`sudo zpool destroy [ZFS_POOL]`

# Nett2Know #
* Activate compression: `sudo zfs set compression=lz4 [ZFS_POOL]`
* Change mountpoint: `sudo zfs set mountpoint=[MOUNTPOINT] [ZFS_POOL]` **DON'T to forget to delete the old mountpoint folder (default is in /)**
* Quotas: `sudo zfs set quota=100m [ZFS_POOL]`
* Snapshotdir: `sudo zfs set snapdir=visible [ZFS_POOL]` visible | hidden
* Subpools (any sub can e.g. have its own options ↑)!
    * List: `sudo zfs list`
    * Create: `sudo zfs create [ZFS_POOL]/[SUB]`
    * Delete: `sudo zfs destroy [ZFS_POOL]/[SUB]`

# Snapshotting #
* List: `sudo zfs list -t snapshot`
* Create: `sudo zfs snapshot [ZFS_POOL]@[SNAPSHOT_NAME]` Add `-r` to snapshot all subpools (or delete)!
* Delete: `sudo zfs destroy [ZFS_POOL]@[SNAPSHOT_NAME]` (use `%` for the snapshots name to delete them all)
* Apply it: `sudo zfs rollback [ZFS_POOL]@[SNAPSHOT_NAME]`
    You want to rollback to an older without the deletion of the newer?
    1. `sudo zfs rename [ZFS_POOL] [ZFS_POOL_OTHER] `
    2. `sudo zfs clone [ZFS_POOL_OTHER]@[SNAPSHOT_NAME] [ZFS_POOL]`

# Auto snapshotting #
Make sure `zfs-auto-snapshot` is installed.
Now add to the crontab (`//` stands for all pools)...
```
*/10 * * * * /usr/sbin/zfs-auto-snapshot -r -q --label=frequently --keep=30 //
@hourly /usr/sbin/zfs-auto-snapshot -r -q --label=hourly --keep=24 //
@daily /usr/sbin/zfs-auto-snapshot -r -q --label=daily --keep=14 //
@weekly /usr/sbin/zfs-auto-snapshot -r -q --label=weekly --keep=8 //
@monthly /usr/sbin/zfs-auto-snapshot -r -q --label=monthly --keep=24 //
@yearly /usr/sbin/zfs-auto-snapshot -r -q --label=yearly --keep=6 //
```
...to snapshort all pools. To exclude a pool set the `com.sun:auto-snapshot` parameter to `false`.
If you get `Error: zpool status 127: env: ‘zpool’: No such file or directory` errors - add this:
```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```
Nett2Know - how you can list specific snapshots for a specific pool: `sudo zfs list -t snapshot [ZFS_POOL] | grep frequent`

# Snapshot replication #
_May used for offsite-backups - the script below had this part(s) removed. So refer to more info (also below)!_
1. Get your source pool ready by creating some snapshots and maybe activating zfs-auto-snapshot...
2. Create your target pool (maybe on an other system)
    * Consider to set it to `readonly=on`
    * ...or to remove its mountpoint...
    * It should also be encrypted if the source was
3. Setup the script
    1. The steps 2 and 4 contains a script which should be added to the daily crontab of root. Make sure to run it with the bash command!
    2. The universal script header (should be run every time before the initial and incremental backup parts)
        ```bash
        #!/bin/bash

        # Setup/variables:

        # Each snapshot name must be unique, timestamp is a good choice.
        # You can also use Solaris date, but I don't know the correct syntax.
        snapshot_string=DO_NOT_DELETE_target_replication_pools_state_
        timestamp=$(date '+%Y%m%d%H%M%S')
        source_pool=[SOURCE_POOL]
        destination_pool=[TARGET_POOL]
        new_snap="$source_pool"@"$snapshot_string""$timestamp"
        ```
    3. Initial setup (first snapshot to init the target pool) - you CAN'T IGNORE the `zfs snapshot -r "$new_snap"` part, otherwise the incremental wouldn't find the refernce point!
        ```bash
        # Initial send:

        # Create first recursive snapshot of the whole pool.
        zfs snapshot -r "$new_snap"
        # Initial replication.
        zfs send -R "$new_snap" | zfs recv -Fdu "$destination_pool"
        ```
    4. Send and receive the pools snapshotted state incrementally by using the following script
        ```bash
        # Incremental sends:

        # Get old snapshot name.
        old_snap=$(zfs list -H -o name -t snapshot -r "$source_pool" | grep "$source_pool"@"$snapshot_string" | tail --lines=1)
        # Create new recursive snapshot of the whole pool.
        zfs snapshot -r "$new_snap"
        # Incremental replication.
        zfs send -RI "$old_snap" "$new_snap" | zfs receive -Fdu -x mountpoint -x readonly "$destination_pool"
        # Delete older snaps on the local source (grep -v inverts the selection)
        delete_from=$(zfs list -H -o name -t snapshot -r "$source_pool" | grep "$snapshot_string" | grep -v "$timestamp")
        for snap in $delete_from; do
            zfs destroy "$snap"
        done
        ```
        The `-x` options are required - otherwise the specified options would be applied on the target pool (don't worry, they will still be transferred)
4. Maybe remove the target pool from the zfs-auto-snapshot script (don't forget to add the `-x` to the `receive` above, so it won't be resetted)
    `zfs set com.sun:auto-snapshot=false`

[More info](https://unix.stackexchange.com/questions/263677/how-to-one-way-mirror-an-entire-zfs-pool-to-another-zfs-pool)

# Move a pool to an other system #
On source PC: `sudo zpool export [ZFS_POOL]`
On target PC: `sudo zpool import [ZFS_POOL]` - omit `[ZFS_POOL]` to see all available

# Not working after reboot? #
[-> see here](https://serverfault.com/questions/708783/zfs-never-mounts-my-pool-automatically-why)

# Help! All my pools are gone... #
...happened to me, after a kernel upgrade. Make sure...
* Don't panic! ZFS is very resilient...
* The `zfs` module is loaded
* May need to `sudo apt install --reinstall zfs-dmks && sudo modprobe zfs` - watch out for errors!
* Reimport the pool "from scratch" (thanks to [here](https://forum.level1techs.com/t/zfs-pool-disappeared-after-an-accidental-shutdown-help/111381)): `sudo zpool import -d /dev/ [POOL_NAME]`
