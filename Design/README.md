# Add adapta theme #
```
sudo add-apt-repository ppa:tista/adapta
```

# Add Papirus icons #
```
sudo add-apt-repository ppa:papirus/papirus
```

# Install them with Roboto #
```
sudo apt-get update
sudo apt-get install adapta-gtk-theme adapta-kde papirus-icon-theme fonts-roboto fonts-hack
```

# Activate them #
Cinnamon / KDE
* * / *: Roboto Regular 10
* Monospace / Fixed width: Hack Regular 10
* - / small: Roboto Light 9
* Document / -: Default with Sans Regular 10

# Unify the themes in editors / IDEs #
Sadly I didn't found a truely universal theme: So here a list of used ones:
* `Solarized Dark` - XED, Kate
* `Norway Today` - Netbeans

# Use the UEFI image at boot #
For that several steps are needed!
1. Go to `/sys/firmware/acpi/bgrt` and make sure the path and a file named `image` exists. If no, then the device doesn't support this!
2. Use `cp /sys/firmware/acpi/bgrt/image /tmp/` to copy the UEFI image and convert it with `mogrify -format png /tmp/image` into a PNG.
3. **Following is FOR LINUX MINT ONLY!**
4. Rename the original logo with `sudo mv -v /usr/share/plymouth/themes/mint-logo/logo.png /usr/share/plymouth/themes/mint-logo/logo.orig.png`
5. And insert the vendors logo `sudo cp -v /tmp/image.png /usr/share/plymouth/themes/mint-logo/logo.png`
6. Now update the initramfs to apply the change at the next reboot with `sudo update-initramfs -u -k all`
