---
summary: The styleguide used to unify the surfaces of all my desktops. It uses Adapta and the Papirus Icon Theme. Also some editor recommendations included.
---

# Add required PPAs #
```bash
sudo add-apt-repository ppa:tista/adapta
sudo add-apt-repository ppa:papirus/papirus
```

# Install them with Roboto fonts #
```bash
sudo apt-get update
sudo apt-get install adapta-gtk-theme adapta-kde papirus-icon-theme fonts-roboto fonts-hack
```

# Activate them in Cinnamon / KDE #
* `* / *`: Roboto Regular 10
* `Monospace / Fixed width`: Hack Regular 10
* `- / small`: Roboto Light 9
* `Document / -`: Default with Sans Regular 10

Select `Adapta-Nocto-Eta` inside "Themes" and `gtk2` inside "Qt5 Settings. Also make sure to select the `Papirus-Dark` icon theme (some icons will be lighter to be better readible on dark backgrounds).
And don't forget to also apply the fonts for qt (also inside the dialog)...

# Unify the themes in editors / IDEs #
Sadly I didn't found a truly universal theme: So here a list of used ones:
* `Solarized Dark` - XED, Kate
* `Norway Today` - Netbeans

# Animations #
...should alwas be `Blend`.

# Display the UEFI image at boot screen #
Tested on Linux Mint Cinnamon 20 - it may breaks on major system upgrades. To prevent this use the automatic way...

## Automatic ##
Install this script and it will be executed on every upgrade by apt.
1. Create the script hook inside the apt config `/etc/apt/apt.conf.d/80upgradehook` by appending:
    ```
    DPkg::Post-Invoke {"/root/update_uefi_image.sh";};
    ```
2. Add the simple script to `/root/update_uefi_image.sh` (as root):
    ```bash
    #!/bin/bash
    if [ ! -f /sys/firmware/acpi/bgrt/image ]; then
        echo "Can't update UEFI boot logo, because the source image is not available."
        exit
    fi
    if [ ! -f /usr/share/plymouth/themes/mint-logo/logo.png ]; then
        echo "Can't update UEFI boot logo, because the target image is not available."
        exit
    fi

    echo "Updating UEFI boot logo..."

    echo "[1/6] Copying image to writeable location..."
    cp /sys/firmware/acpi/bgrt/image /tmp/

    echo "[2/6] Converting image to PNG..."
    mogrify -format png /tmp/image

    echo "[3/6] Backing up original image..."
    mv /usr/share/plymouth/themes/mint-logo/logo.png /usr/share/plymouth/themes/mint-logo/logo.png.bak

    echo "[4/6] Replacing image..."
    cp /tmp/image.png /usr/share/plymouth/themes/mint-logo/logo.png

    echo "[5/6] Rebuilding initramfs image..."
    update-initramfs -u -k all

    echo "[6/6] Cleanup..."
    rm /tmp/image
    rm /tmp/image.png

    echo "Done."
    ```
3. Mark it as executeable and secure it:
    ```bash
    sudo chmod 550 /root/update_uefi_image.sh
    ```

## Manual ##
1. Go to `/sys/firmware/acpi/bgrt` and make sure the path and a file named `image` exists. If no, then the device doesn't support this!
2. Use `cp /sys/firmware/acpi/bgrt/image /tmp/` to copy the UEFI image and convert it with `mogrify -format png /tmp/image` into a PNG.
3. Rename the original logo with `sudo mv -v /usr/share/plymouth/themes/mint-logo/logo.png /usr/share/plymouth/themes/mint-logo/logo.orig.png`
4. And insert the vendors logo `sudo cp -v /tmp/image.png /usr/share/plymouth/themes/mint-logo/logo.png`
5. Now update the initramfs to apply the change at the next reboot with `sudo update-initramfs -u -k all`
