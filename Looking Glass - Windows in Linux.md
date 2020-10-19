---
summary: Notes how to setup and use Looking Glass
---

> At the time of testing the mouse and keyboard support was... Lets call it non-deterministic.

# Prepare PCIe #
https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
...so the vm could restart and reset own GPU for that. Otherwise cold VM boot needed.

# Windows install #
* [BSOD with system_thread_exception_not_handled](https://www.reddit.com/r/VFIO/comments/8gdbnm/ryzen_2700_system_thread_exception_not_handled/) -> AMD EPYC is killing the windows kernel. Epic.
* QEMU guest tools
* Should use UEFI
* Maybe install virtio drivers for SCSI or so...

# Looking glass #
* Used release was R1
* General guide: https://looking-glass.hostfission.com/wiki/Installation
    * Download and compile the linux client (goto client/, cmake ./, make -j 24 looking-glass-client)
    * Download and upload windows binaries and installed as task `SCHTASKS /Create /TN "Looking Glass" /SC  ONLOGON /RL HIGHEST /TR C:\looking-glass-host.exe`
    * Modfiy KVM to provide shared mem https://looking-glass.hostfission.com/wiki/Installation#libvirt_Configuration
    * Error on kvm init after prev step?
        ```bash
        touch /dev/shm/looking-glass
        chown user:kvm /dev/shm/looking-glass
        ```
        Following is needed after every reboot
        ```bash
        chmod 660 /dev/shm/looking-glass
        ```
        Insert `/{dev,run}/shm/looking-glass rw,` into /etc/apparmor.d/abstractions/libvirt-qemu
        ```bash
        sudo systemctl reload apparmor
        ```
    * Cold boot + install driver https://looking-glass.hostfission.com/wiki/Installation#Installing_the_IVSHMEM_Driver
* Start client with `./looking-glass-client -k -M -a -S -d`
* If eGL error 0x3005: AMD has dropped support of OpenGL ES in propertary drivers -> revert back to MESA drivers
* Make sure to add a SPICE display and e.g. cirrus video adapter, which should be disabled (QEMU 4+ alklows none as type)
* The passed trough GPU should have a monitor attached: Use a dummy DP / HDMI plug

# If Looking glass is not used... #
...consider something like evdev passthrough.

# NVIDIA error 43 #
https://passthroughpo.st/apply-error-43-workaround/

# No sound? #
https://passthroughpo.st/how-to-patch-qemu-and-fix-vm-audio/
