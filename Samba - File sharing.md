---
summary: A config template with examples for permission enforcement and performance tweaking
---

THIS ALL REQUIRES the `samba` package
Located at `/etc/samba/smb.conf`

```ini
[global]
workgroup = WORKGROUP
server string = %h
#hosts allow = localhost 127.0.0.1 192.168.0.0/24
#hosts deny = 0.0.0.0/0
server role = standalone server
dns proxy = no
name resolve order = bcast host
unix extensions = yes
# Manage the user passwords explicitly by using smbpasswd; ignoring a entually locked linux-user password
unix password sync = no
# Speed up man!
socket options = TCP_NODELAY IPTOS_LOWDELAY
strict sync = no
sync always = no

# Permissions USE sudo smbpasswd -a USER to add user, USE sudo smbpasswd -x USER to remove user
guest account = nobody
security = user
invalid users = root
guest ok = yes
# Following: Bad password (and username is unknown) -> treat as guest!
map to guest = bad user

# Something just won't work? Try more detailed logs!
#log level = 2

# GOLBAL: Delete moves to trash - REQUIRES samba-vfs-modules
#vfs objects = recycle shadow_copy2
#recycle:repository = Samba Trash
#recycle:keeptree = yes
#recycle:touch = yes
#recycle:versions = yes
#recycle:maxsize = 0

# Enable Windows file history support - REQUIRES samba-vfs-modules and zfs with configured zf-auto-snapshots
#shadow:snapdir = .zfs/snapshot
#shadow:snapprefix = zfs-auto-snap_.*
#shadow:delimiter = ly-
#shadow:format = ly-%Y-%m-%d-%H%M
#shadow:localtime = yes

# The the following forces any new file to permission 0777 (open to anyone), can also applied on a per-share level...
create mask = 0777
directory mask = 0777
force create mode = 0777
force directory mode = 0777

# Share for the printers (useless on servers without attached printers)
[printers]
    comment = All Printers
    path = /var/spool/samba
    browseable = no
    guest ok = yes
    public = yes
    writable = no
    printable = yes


# Now some example shares (add "browseable = no" to them to hide it)


[Home]
   path = /home/glaforge
   comment = Home folder
   guest ok = no
   writeable = yes
   valid users = glaforge
   
[Manuals]
   path = /mnt/manuals
   comment = Manuals to handle the U.S.S. Enterprise
   guest ok = no
   writeable = no
   valid users = glaforge jpicard
   write list = glaforge

[Temp]
   path = /mnt/temp
   # You'll need a cronjob like this: @daily find "/mnt/temp" -mindepth 1 -mtime +1 -delete >/dev/null 2>&1
   comment = Temorary files (24h lifetime)
   guest ok = yes
   writeable = yes
   # Make sure everyone can edit every (new) file here!
   create mask = 0777
   directory mask = 0777
   force create mode = 0777
   force directory mode = 0777

[Backups]
   path = /mnt/backups
   comment = Automatic backups! Very important!
   guest ok = no
   writeable = no
   valid users = glaforge jpicard
   write list = glaforge
# Prevent accidential deletions - REQUIRES samba-vfs-modules
   vfs objects = recycle shadow_copy2
   recycle:repository = Samba Trash
   recycle:keeptree = yes
   recycle:touch = yes
   recycle:versions = yes
   recycle:maxsize = 0
   
[Windows Backups]
   path = /mnt/nfs/wbackups
   browseable = no
   guest ok = no
   valid users = glaforge windowsbackup
   writable = yes
   # The following is needed, when the path is located on a NFS mounted device!
   store dos attributes = no

#[Folder Template]
#   path = /path/to/data
#   comment = miniDLNA server space
# Make sure everyone can edit every (new) file here!
#   create mask = 0777
#   directory mask = 0777
#   force create mode = 0777
#   force directory mode = 0777
# Prevent accidential deletions
#   vfs objects = recycle shadow_copy2
#   recycle:repository = Samba Trash
#   recycle:keeptree = yes
#   recycle:touch = yes
#   recycle:versions = yes
#   recycle:maxsize = 0
# Private Access XOR...
#   guest ok = no                            
#   writeable = no
#   valid users = glaforge jpicard
#   write list = glaforge
# Public Access
#   guest ok = yes
#   writeable = yes
```
