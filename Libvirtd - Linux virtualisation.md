---
summary: Server, client, shared folders, freezing at host down-times and much, much more!
---

# SERVER #

## Setup ##
1. `sudo apt install libvirt-daemon libvirt-bin qemu-kvm qemu-utils`
2. `sudo apt install ebtables firewalld dnsmasq`

## Setup (Debian Jessie+) ##
The first command should be:
`sudo apt install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils`

## Support guest UEFI ##
`sudo apt install ovmf`

## Allow a user to control the kvm ##
1. `sudo addgroup [USER] kvm`
2. `sudo addgroup [USER] libvirt`

## Firewalld - MAKE SURE TO FIX THAT BUG (if neccessary) ###
Add/Replace this to `/etc/firewalld/firewalld.conf`
```
CleanupOnExit=no
```
_Otherwise a reboot could take up to several minutes!_

### Useful commands for firewalld ###
* Configure:
    * `sudo firewall-cmd --state`
    * `firewall-cmd --get-active-zones`
* What default zones is active? `firewall-cmd --get-default-zone`
* What zones is active on...? `firewall-cmd --get-zone-of-interface [INTERFACE_NAME]`
* List all services which are known: `firewall-cmd --get-services`
* Add a service for an zone: `sudo firewall-cmd --permanent --add-service=[SERVICE_NAME] --zone=[ZONE_NAME]`
* Add a port for an zone: `sudo firewall-cmd --permanent --add-port=[PORT]/tcp --zone=[ZONE_NAME]`
* Disable firewall COMPLETLY for an interface: `sudo firewall-cmd --permanent --zone=trusted --change-interface=[INTERFACE_NAME]`
* Disable firewall COMPLETLY for ALL interfaces (permanently only): `sudo firewall-cmd --set-default-zone=trusted`

**[More info (firewalld)](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7)**

## Enable automatic freezing of guests at host reboot ##
1. Add a new service
    ```systemd
    [Unit]
    Description=VMFreezer - saves / restores all running machines of libvirt from / to disk
    Requires=libvirtd.service
    #libvirt-guests.service is in after, because @shutdown this order is inverse!
    #Add here the required path (maybe to save the states on external disks) from /etc/fstab (slash must be a dash)
    #MAYBE add mnt-raid01.mount to wait for a specific mount point...
    After=network.service libvirtd.service libvirt-guests.service
    #Before=

    [Service]
    Type=oneshot
    #infinity -> make sure we wait for ANY vm!
    TimeoutSec=infinity
    RemainAfterExit=true
    ExecStart=/root/restore.sh
    ExecStop=/root/save.sh

    [Install]
    WantedBy=multi-user.target
    ```
2. Add the required restore script to `/root/restore.sh` (**make sure to change the target path!**)
    ```bash
    #!/bin/bash
    # Restore all guests from saved state and start

    cd /mnt/
    echo "Working in `pwd`."
    ls -1 *.state | \
    while read GUEST; do
        echo "Restoring $GUEST..."
        virsh restore $GUEST --running
        if [ $? -eq 0 ]; then
            echo "Removing the old state $GUEST..."
            rm $GUEST
        else
            echo "Start of $GUEST failed. The state will be moved to /tmp/ - so it can manually restored... Eventually..."
            mv $GUEST /tmp/
        fi
        # Now sleep a shot period of time to make sure, that e.g. dynamic memory has been populated properly...
        sleep 5
    done
    ```
3. Add the required save script to `/root/save.sh` (**make sure to change the target path!**)
    ```bash
    #!/bin/bash
    # Save (store ram and shutdown) all guests

    cd /mnt/
    echo "Working in `pwd`."
    virsh list | `#list of running guest` \
    tail -n +3 | head -n -1 | sed 's/\ \+/\t/g' | `#strip head and tail, use tab for seperator`\
    awk '{print($2)}' | \
    while read GUEST; do
        echo "Saving $GUEST..."
        virsh save $GUEST $GUEST.state
    done
    ```
4. Mark the scripts as executable: `sudo chmod 555 /root/save.sh /root/restore.sh`

### Install the startup vm service ###
1. Add the `vmfreezer.service` file to `/etc/systemd/system`
2. Add the `save.sh` file to `/root`
3. Add the `restore.sh` file to `/root`
4. Set permissons for them `sudo chmod 500 /root/save.sh /root/restore.sh`
5. DON'T FORGET to modify the scripts to use the correct path to save and restore the vms!
6. Enable the new service with `sudo systemctl enable vmfreezer`

## Shared folders ##

### KVM ###
Just add a new mapped shared folder with a new [TARGET_PATH].
To mount it, just insert following line into the guests `/etc/fstab`:
```
[TARGET_PATH]    [LOCAL_PATH]       9p      trans=virtio,version=9p2000.L,msize=262144    0       0
```
IF you get emergency boot failures - insert the following into `/etc/initramfs-tools/modules`:
```
9p
9pnet
9pnet_virtio
```
...and update `sudo update-initramfs -u`!

If the listing of much files is too slow, try enabling the cache ([copied from here](https://www.kernel.org/doc/Documentation/filesystems/9p.txt)):
```
cache=mode	specifies a caching policy.  By default, no caches are used.
        none = default no cache policy, metadata and data
                alike are synchronous.
        loose = no attempts are made at consistency,
                intended for exclusive, read-only mounts
        fscache = use FS-Cache for a persistent, read-only
	            cache backend.
        mmap = minimal cache that is only used for read-write
                mmap.  Northing else is cached, like cache=none
```

### Samba ###
#### Install server... ####
`sudo apt install samba`

#### Add a virtual isolated network for loopback communication with the host and vm ####
* Make sure to enable DHCP, so the host will listen to the clients (instead being REALLY isolated).
* Add this interface (e.g. virbr1) to the firewall (trusted zone is okay - because the VMs should have a second interface anyway which is in the same network like the host)...
* _Note that the host can contact the VMs ONLY using that networks IPs from this network!_
* **Because the host is _always faster_ than the other network interfaces you REALLY SHOULD apply the following fix:**
    1. Use the command `sudo virsh net-edit [LOCALSTORAGENET_NAME]` to open the xml-configuration-file of the virtual network.
    2. Add there the following code (if you add any other entry than the one domain=... the host will resolve the request for the client - so don't be confused if the /etc/resolv.conf specifies then the host as dns provider)...
        ```xml
        <network>
        ...
        <dns>
        <forwarder domain='router.domain'/>
        <forwarder addr='1.1.1.1'/>
        </dns>
        ...
        </network>
        ```
        ...to forward any request to either the real network dns provider or e.g. Cloudflare!
    3. Save it, restart the network and reboot any vms to apply the fix!

#### Setup the smb.conf to... ####
```
#THIS ALL REQUIRES samba
#This is lacated at /etc/samba/smb.conf

[global]
#Network stuff
workgroup = WORKGROUP
server string = %h
#Following: Set it to the servers local IP (the one from virbr1 / localhost)
#hosts allow = localhost 127.0.0.1 192.168.0.0/24
#hosts deny = 0.0.0.0/0
dns proxy = no
disable netbios = yes
name resolve order = bcast host

#Permissions USE sudo smbpasswd -a USER to add user, USE sudo smbpasswd -x USER to remove user
guest account = nobody
security = user
encrypt passwords = true
invalid users = root
guest ok = no

#Stuff
unix extensions = yes
unix password sync = no
usershare owner only = yes
#Log size in Kb
max log size = 50

#Server role inside the network
server role = standalone server

#Fix the permissions to allow group access!
#force user = [USER (Only if neccessary)]
force group = [FSgroup]
#Following seems to be useless with the following fixes...
#create mask = 770
#FIX permission: File: UPPER bound for the bits
create mode = 770
#FIX permission: File: LOWER bound for the bits
force create mode = 770
#FIX permission: Directory: UPPER bound for the bits
directory mode = 770
#FIX permission: Directory: LOWER bound for the bits
force directory mode = 770

#
#NOTE:
#browseable = no -> Hidden share
#

[Share1]
    path = [PATH]
    available = yes
    #Following to hide it anyways!
    browseable = no
    guest ok = no
    #Following to make read only if no user is in the write list!
    writeable = no
    valid users = [VirtUsers]
    write list = [VirtUsers]
```

### VM - Allow a vm access to a specific share... ####
Nett2Know: Use `sudo pdbedit -L` to get current user list...
1. Add an account on the host (nologin, nohome) with `sudo adduser --no-create-home --shell /usr/sbin/nologin --disabled-login [USER]`
2. Add this account to the FSgroup `sudo adduser [USER] [FSgroup]`
3. Allow samba to map to this account (now is a good PWD neccessary) `sudo smbpasswd -a [USER]`
4. Add the account to the shares at the smb.conf
5. Add the share to the vm and save the credentials there (next paragraph)

### Setup a vm to access and mount a specific share ###
Add this to fstab (it will mount on first access - this is neccessary, because some (...) systemd instances ignore the \_netdev option) `//[HOST_LOCALSTORAGENET_IP]/[SHARE_NAME]  [TARGET_PATH]	cifs noauto,x-systemd.automount,x-systemd.idle-timeout=5m,_netdev,nouser,mapchars,cache=strict,noacl,credentials=[CREDENTIAL_FILE (e.g. /root/creds)],domain=workgroup,uid=root,gid=[VM_SHARED_FOLDER_GROUP],file_mode=0770,dir_mode=0770 0   0`
_On cd-failures with error -13 you fucked up the password or username!_
_Use cache=strict to fix ghosting folders (if they still appear use 'none' - BUT THIS WILL IMPACT PERFORMACE). When there are no ghosting folders or files you can try to use 'loose' to further improve performance._

### Setup a vm to make shares available (needed only ONCE)... ###
1. Install cifs `sudo apt install cifs-utils`
2. Add the host localstorage interface to /etc/network/interfaces: `iface [INTERFACE_NAME] inet dhcp`
3. Add a group for the shares `sudo addgroup [VM_SHARED_FOLDER_GROUP]`
4. Add a user to this group `sudo addgroup [USER (e.g. www-data)] [VM_SHARED_FOLDER_GROUP]`
5. Create the authentication file (e.g. /root/creds):
    ```
    username=[USERNAME]
    password=[PASSWORD]
    ```
6. Set permissons for the credential file `sudo chmod 500 [CREDENTIAL_FILE (e.g. /root/creds)]`

# VIRTUAL MACHINE #

## VM - Allow multicast packages ##
_Multicast packages are generated by e.g. the avahi daemon or minidlna and is neccessary to use the avahi zeroconf service (needed for media streaming etc)._
1. Show all running vms: `sudo virsh list`
2. Edit the xml file of the machine, which _should_ be allowed to send out these packages: `sudo virsh edit X`
3. Go down to the network interface which should be allowed (e.g. NOT the [LOCALSTORAGENET]) to do that and change the following code
    ```xml
    <devices>
    ...
    <interface type='XXX'>
    ...
    </interface>
    ...
    </devices>
    ```
    to
    ```
    <devices>
    ...
    <interface type='XXX' trustGuestRxFilters='yes'>
    ...
    </interface>
    ...
    </devices>
    ```
4. Cold-boot the vm.

## VM - Enable TRIM to save image space ##
1. Change disk type to SCSI
2. Change the controller type to VirtIO SCSI
3. Show all running vms: `sudo virsh list`
4. Edit the xml file of the machine, which _should_ be allowed to send out these packages: `sudo virsh edit X`
5. Add the unmap flag to the disk:
    ```xml
    ...
    <disk type='file' device='disk'>
    <driver name='qemu' type='qcow2'/>
    ...
    </disk>
    ...
    ```
    to
    ```
    ...
    <disk type='file' device='disk'>
    <driver name='qemu' type='qcow2' discard='unmap'/>
    ...
    </disk>
    ...
    ```
6. Enable the trim service (on older versions of Debian first run `sudo cp /usr/share/doc/util-linux/examples/fstrim.{service,timer} /etc/systemd/system`):
    ```bash
    sudo systemctl enable fstrim.timer
    sudo systemctl start fstrim.timer
    sudo fstrim -av
    ```
    _The last command just trims the ssd for the first time._
7. Cold-boot the vm.

* [More info](https://blog.zencoffee.org/2016/05/trim-support-kvm-virtual-machines/)
* [For windows vms](https://pve.proxmox.com/wiki/Shrink_Qcow2_Disk_Files#Windows_Guest_Configuration)

## [VM - Install windows support here](https://www.spice-space.org/download.html) ##

# CLIENT(S) #

## Setup management-client ##
```bash
sudo apt install virt-manager spice-client-gtk gir1.2-spiceclientgtk-3.0
```

## Setup viewonly-client ##
```bash
sudo apt install virt-viewer
```

# [MORE INFO](https://help.ubuntu.com/community/KVM/VirtManager) #
