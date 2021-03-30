---
summary: WSDD for service discovery under Windows, as it is too incompetent to use Avahi/Zeroconf
---

# Why?
This enables Windows to still see some major Linux services, as it is too incompetent to use some broadly available solution like Avahi. With newer Windows versions also the support
for NETBIOS names has been removed, so newer Windows versions can't even see any Samba share anymore...

# Install
Navigate to [here](https://pkg.ltec.ch/public/pool/main/w/wsdd/) to get the newest `wsdd` binaries for Debian.
Then download & install it:
```bash
wget "[PATH_TO_WSDD_DEB_FILE]"
sudo apt install ./[WSDD_DEB_FILE]
sudo systemctl enable wsdd
```
Done. That's it!
