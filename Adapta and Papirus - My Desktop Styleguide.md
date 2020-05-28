---
summary: The styleguide used to unify the surfaces of all my desktops. It uses Adapta and the Papirus Icon Theme. Also some editor recommendations included.
---

# Add required PPAs #
```
sudo add-apt-repository ppa:tista/adapta
sudo add-apt-repository ppa:papirus/papirus
```

# Install them with Roboto fonts #
```
sudo apt-get update
sudo apt-get install adapta-gtk-theme adapta-kde papirus-icon-theme fonts-roboto fonts-hack
```

# Activate them in Cinnamon / KDE #
* * / *: Roboto Regular 10
* Monospace / Fixed width: Hack Regular 10
* - / small: Roboto Light 9
* Document / -: Default with Sans Regular 10

# Unify the themes in editors / IDEs #
Sadly I didn't found a truly universal theme: So here a list of used ones:
* `Solarized Dark` - XED, Kate
* `Norway Today` - Netbeans

# Display the UEFI image at boot screen #
Tested on Linux Mint Cinnamon 19.3
1. Go to `/sys/firmware/acpi/bgrt` and make sure the path and a file named `image` exists. If no, then the device doesn't support this!
2. Use `cp /sys/firmware/acpi/bgrt/image /tmp/` to copy the UEFI image and convert it with `mogrify -format png /tmp/image` into a PNG.
3. Rename the original logo with `sudo mv -v /usr/share/plymouth/themes/mint-logo/logo.png /usr/share/plymouth/themes/mint-logo/logo.orig.png`
4. And insert the vendors logo `sudo cp -v /tmp/image.png /usr/share/plymouth/themes/mint-logo/logo.png`
5. Now update the initramfs to apply the change at the next reboot with `sudo update-initramfs -u -k all`
