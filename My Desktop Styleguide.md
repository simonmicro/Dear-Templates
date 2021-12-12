---
summary: The styleguide used to unify the surfaces of all my desktops. It uses Plata and the Papirus Icon Theme. Also some editor recommendations included.
---

# Add PPAs
```bash
sudo add-apt-repository ppa:tista/plata-theme # Light & Dark theme
sudo add-apt-repository ppa:papirus/papirus # Icon theme
```

# Install packages
```bash
sudo apt-get update
sudo apt-get install plata-theme papirus-icon-theme fonts-roboto fonts-hack
```

# Cinnamon: Automatic daylight rotation
In Cinnamon there is a new [applet](https://cinnamon-spices.linuxmint.com/applets/view/347), which allows you to switch between light and dark themes automatically.
To configure it, you should select `Plata-Lumine` and `Plata-Noir` for Light and Dark Mode respectively. For the icon theme switch between `Papirus-Light` and `Papirus-Dark`.
_I also prefer to configure automatic mode switching._

Select `gtk2` inside "Qt5 Settings". Also make sure to select the `Papirus-Dark` icon theme (some icons will be lighter to be better readible on dark backgrounds).
And don't forget to also apply the fonts for qt (also inside that dialog)...

# Fonts in Cinnamon / KDE
* `* / *`: Roboto Regular 10
* `Monospace / Fixed width`: Hack Regular 10
* `- / small`: Roboto Light 9
* `Document / -`: Default with Sans Regular 10

# Unify the themes...
Sadly I didn't found a truly universal theme for all editors - so here a list of used ones:
* `XED`, `Kate` - Solarized Dark
* `Netbeans` - Norway Today
* `Visual Studio Code` - Dark+ / Light+

Also make sure to configure the following applications:
* `Discord` - Well, it works but only on startup...
* `Thunderbird`
* `Firefox`
* `Signal`
* `Telegram`

# Animations
...should alwas be `Blend`.

# Display the UEFI image at boot screen
Tested on Linux Mint Cinnamon 20 - it may breaks on major system upgrades. To prevent this use the automatic way: Install this script and it will be executed on every upgrade by `apt`.
1. Add the simple script to `/etc/kernel/postinst.d/uefi_boot_image.sh` (as root, that is not perfect - but good enough):
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
2. Mark it as executeable and secure it:
    ```bash
    sudo chmod 550 /etc/kernel/postinst.d/uefi_boot_image.sh
    ```
