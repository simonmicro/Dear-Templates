# Setup on Debian (10) #
1. Add the "contib" and "non-free" branch to the `/etc/apt/sources.list`
2. Install zfs: `sudo apt install zfsutils-linux`
3. Reboot or modprobe (`sudo modprobe zfs`) to activate zfs

# Under Debian 10: Upgrade to zfs 0.8+ #
...otherwise the encryption won't exist.
Add `deb http://deb.debian.org/debian buster-backports main` to the sources.list and run `sudo apt update`

# Create a pool #
1. Create (for device use: _/dev/disk/by-id/..._): `sudo zpool create [ZFS_POOL] [DEVICE/FILE]` <- **APPEND `-o ashift=12` IF THE DEVICE IS A REAL DISK**
1.1 Oh, I see - you want encryption (a SUBPOOL is recommended - do not encrypt the root one, so you can't creaty any unencrypted anymore...)? You have to create a key and then tell zfs to use it ([take a note](https://www.reddit.com/r/zfs/comments/bnvdco/zol_080_encryption_dont_encrypt_the_pool_root/)):
    * `openssl rand -hex -out /media/stick/key 32`
    * `zfs create -o encryption=on -o keyformat=hex -o keylocation=file:///media/stick/key [ZFS_POOL]` **use -O at zpool to pass them to zfs, otherwise -o is enough**
1.2 And RAID? Of course RAID 5!
    * Create: `sudo zpool create -f [ZFS_POOL] raidz [DEVICE/FILE] [DEVICE/FILE] [DEVICE/FILE]` <- **Add won't work here!**
    * Replace: `sudo zpool replace [ZFS_POOL] [DEVICE/FILE] [DEVICE/FILE]`
    * Detach the failed: `sudo zpool detach [ZFS_POOL] [DEVICE/FILE]` <- **Maybe offlining first**

# Load all the encryption keys at startup #
Add the service: `/etc/systemd/system/zfs-load-all-keys.service`
```
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
* Delete: `sudo zfs destroy [ZFS_POOL]@[SNAPSHOT_NAME]`
* Apply it: `sudo zfs rollback [ZFS_POOL]@[SNAPSHOT_NAME]`
    You want to rollback to an older without the deletion of the newer?
    1. `sudo zfs rename [ZFS_POOL] [ZFS_POOL_OTHER] `
    2. `sudo zfs clone [ZFS_POOL_OTHER]@[SNAPSHOT_NAME] [ZFS_POOL]`

# Auto snapshotting #
Make sure `zfs-auto-snapshot` is installed.
Now add to the crontab (`//` stands for all pools)...
```
*/5 * * * * /sbin/zfs-auto-snapshot -r -q --label=frequent --keep=30 //
@hourly /sbin/zfs-auto-snapshot -r -q --label=hourly --keep=24 //
@daily /sbin/zfs-auto-snapshot -r -q --label=daily --keep=14 //
@weekly /sbin/zfs-auto-snapshot -r -q --label=weekly --keep=8 //
@monthly /sbin/zfs-auto-snapshot -r -q --label=monthly --keep=24 //
@yearly /sbin/zfs-auto-snapshot -r -q --label=yearly --keep=6 //
```
...to snapshort all pools. To exclude a pool set the `com.sun:auto-snapshot` parameter to `false`.

# Move a pool to an other system #
On source PC: `sudo zpool export [ZFS_POOL]`
On target PC: `sudo zpool import [ZFS_POOL]` - omit `[ZFS_POOL]` to see all available

# Not working after reboot? #
[-> see here](https://serverfault.com/questions/708783/zfs-never-mounts-my-pool-automatically-why)
