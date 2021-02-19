---
summary: Only some setup notes.
---

# TFTP-Flash
* Make sure to set your PCs IPv4 to `192.168.0.66`.
* Install `tftp-hda`...
* `sudo tcpdump 'port 69' -vv` for debugging...
* Put an img with name `ArcherC6v2_tp_recovery.bin` into `/var/lib/tftpboot`.

# Config
* Change root password
* Bind all interfaces together
* Use the DHCP client
* Make sure we only use ONE VLAN (eth0 tagged, rest untagged)
* Minimize to only use one firewall rule
* Disable SSH
* Add WiFis
* Bridge now all wifi and lans
* Install wifi-schedule (`luci-app-wifischedule`)

...before restoring any configs make sure to install the previous packages again...
