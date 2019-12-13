# SERVER #

## Server - Setup ##
1. `sudo apt install libvirt-daemon libvirt-bin qemu-kvm qemu-utils`
2. `sudo apt install ebtables firewalld dnsmasq`

## Server - Setup (Debian Jessie+) ##
The first command should be:
`sudo apt install libvirt-daemon-system libvirt-clients qemu-kvm qemu-utils`

## Server - Guest UEFI ##
`sudo apt install ovmf`

## Server - allow users to control the kvm ##
1. `sudo addgroup [USER] kvm`
2. `sudo addgroup [USER] libvirt`

## Server - Firewalld ##

### MAKE SURE TO FIX THAT BUG (IF NECCESSARY) ###
Add/Replace this to /etc/firewalld/firewalld.conf
CleanupOnExit=no
_Otherwise a reboot could take several minutes!_

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

### [More info (firewalld)](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7) ###

## Server - Shared folders ##

### Install server... ###
`sudo apt install samba`

### Add a virtual isolated network for loopback communication with the host and vm ###
* Make sure to enable DHCP, so the host will listen to the clients (instead being REALLY isolated).
* Add this interface (e.g. virbr1) to the firewall (trusted zone is okay - because the VMs should have a second interface anyway which is in the same network like the host)...
* _Note that the host can contact the VMs ONLY using that networks IPs from this network!_
* **Because the host is _always faster_ than the other network interfaces you REALLY SHOULD apply the following fix:**
    1. Use the command `sudo virsh net-edit [LOCALSTORAGENET_NAME]` to open the xml-configuration-file of the virtual network.
    2. Add there the following code (if you add any other entry than the one domain=... the host will resolve the request for the client - so don't be confused if the /etc/resolv.conf specifies then the host as dns provider)...
        ```
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

### Setup the smb.conf to... ###
...the example config (the one with this file)!

## Server - install the startup vm service ##
1. Add the `vmfreezer.service` file to `/etc/systemd/system`
2. Add the `save.sh` file to `/root`
3. Add the `restore.sh` file to `/root`
4. Set permissons for them `sudo chmod 500 /root/save.sh /root/restore.sh`
5. DON'T FORGET to modify the scripts to use the correct path to save and restore the vms!
6. Enable the new service with `sudo systemctl enable vmfreezer`

# VIRTUAL MACHINE #

## VM - shared folders ##

### Allow a vm access to a specific share... ###
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

## VM - Allow multicast packages ##
_Multicast packages are generated by e.g. the avahi daemon or minidlna and is neccessary to use the avahi zeroconf service (needed for media streaming etc)._
1. Show all running vms: `sudo virsh list`
2. Edit the xml file of the machine, which _should_ be allowed to send out these packages: `sudo virsh edit X`
3. Go down to the network interface which should be allowed (e.g. NOT the [LOCALSTORAGENET]) to do that and change the following code
    ```
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
    ```
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
6. Enable the trim service (here on debian):
    1. `sudo cp /usr/share/doc/util-linux/examples/fstrim.{service,timer} /etc/systemd/system`
    2. `sudo systemctl enable fstrim.timer`
    3. `sudo systemctl start fstrim.timer`
7. Cold-boot the vm.

* [More info](https://blog.zencoffee.org/2016/05/trim-support-kvm-virtual-machines/)
* [For windows vms](https://pve.proxmox.com/wiki/Shrink_Qcow2_Disk_Files#Windows_Guest_Configuration)

## [VM - Install windows support here](https://www.spice-space.org/download.html) ##

# CLIENT(S) #

## Setup management-client ##
* `sudo apt install virt-manager spice-client-gtk gir1.2-spiceclientgtk-3.0`

## Setup viewonly-client ##
* `sudo apt install virt-viewer`

# [MORE INFO](https://help.ubuntu.com/community/KVM/VirtManager) #
