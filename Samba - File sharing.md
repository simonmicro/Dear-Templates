---
summary: A config template with examples for permission enforcement and performance tweaking
---

THIS ALL REQUIRES the `samba` package
Located at `/etc/samba/smb.conf`

```ini
[global]
# Network stuff
workgroup = WORKGROUP
server string = %h
#hosts allow = localhost 127.0.0.1 192.168.0.0/24
#hosts deny = 0.0.0.0/0
# Say that samba will only bind to the default ip of an interface...
bind interfaces only
dns proxy = no
disable netbios = yes
name resolve order = bcast host
# Speed up man!
socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=65536 SO_SNDBUF=65536
strict sync = no
sync always = no

# Permissions USE sudo smbpasswd -a USER to add user, USE sudo smbpasswd -x USER to remove user
guest account = nobody
security = user
encrypt passwords = true
invalid users = root
guest ok = yes
# Following: Bad login credentials -> guest access level
map to guest = bad user

# Stuff
unix extensions = yes
unix password sync = no
usershare owner only = yes

# GOLBAL: Delete moves to trash - REQUIRES samba-vfs-modules
#vfs objects = recycle shadow_copy2
#recycle:repository = Samba Trash
#recycle:keeptree = yes
#recycle:touch = yes
#recycle:versions = yes
#recycle:maxsize = 0
#shadow:snapdir = .zfs/snapshot
#shadow:snapprefix = zfs-auto-snap_.*
#shadow:delimiter = ly-
#shadow:format = ly-%Y-%m-%d-%H%M
#shadow:localtime = yes

# Server role inside the network
server role = standalone server

#
# NOTE:
#browseable = no -> Hidden share
#


###EVERYTHING BELOW THIS LINE IS UNIQUE AND SHOULD NOT OVERWRITTEN ON CONFIG-UPDATES!


[printers]
    comment = All Printers
    path = /var/spool/samba
    browseable = no
    guest ok = yes
    public = yes
    writable = no
    printable = yes

[Home]
   path = /home/jlaforge
   comment = Home folder
   available = yes
   browseable = yes
   guest ok = no
   writeable = no
   valid users = jlaforge
   write list = jlaforge

[Main drive]
   path = / 
   comment = Main system drive
   available = yes
   browseable = yes                         
   guest ok = no                            
   writeable = no
   valid users = jlaforge
   write list = jlaforge

#[Temp]
#   path = /media/sf_Temp
#   comment = Temorary files (48h lifetime)
#   available = yes
#   browseable = yes
#   guest ok = yes
#   writeable = yes

#[Archive]
#   path = /media/sf_Archive
#   comment = Archive
#   available = yes
#   browseable = yes                         
#   guest ok = no                            
#   writeable = no
#   valid users = jlaforge
#   write list = jlaforge
#   #LOCAL: Delete moves to trash - REQUIRES samba-vfs-modules
#   vfs objects = recycle shadow_copy2
#   recycle:repository = Samba Trash
#   recycle:keeptree = yes
#   recycle:touch = yes
#   recycle:versions = yes
#   recycle:maxsize = 0

#[Backup]
#   path = /media/sf_Backup
#   comment = Backups
#   available = yes
#   browseable = yes                         
#   guest ok = no                            
#   writeable = no
#   valid users = jlaforge
#   write list = jlaforge
#   #LOCAL: Delete moves to trash - REQUIRES samba-vfs-modules
#   vfs objects = recycle shadow_copy2
#   recycle:repository = Samba Trash
#   recycle:keeptree = yes
#   recycle:touch = yes
#   recycle:versions = yes
#   recycle:maxsize = 0

#[Shared data]
#   path = /media/sf_Data
#   comment = Several shared data files
#   available = yes
#   browseable = yes                         
#   guest ok = no                            
#   writeable = no
#   valid users = jlaforge
#   write list = jlaforge
# The the following forces any new file to permission 0770...
#   create mask = 0770
#   security mask = 0770
#   directory mask = 0770
#   directory security mask = 0770
#   force create mode = 0770
#   force security mode = 0770
#   force directory mode = 0770
#   force directory security mode = 0770

#[Data]
#   path = /media/sf_Data
#   comment = Several data files
#   available = yes
#   browseable = yes                         
#   guest ok = no                            
#   writeable = no
#   valid users = jlaforge
#   write list = jlaforge

#[miniDLNA]
#   path = /media/sf_Data/miniDLNA
#   comment = miniDLNA server space
#   available = yes
#   browseable = yes
# Private Access XOR                    
#   guest ok = no                            
#   writeable = no
#   valid users = jlaforge
#   write list = jlaforge
# Public Access
#   guest ok = yes
#   writeable = yes
```
