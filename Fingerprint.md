---
title: Fingerprint
summary: How to setup fprint and how to use fringerprint based login with KDE plasma
type: blog
banner: "/img/dear-templates/default.jpg"
---

# Setup fprint for your user #
1. Install `sudo apt install fprint`
2. Enroll a finger `sudo fprintd-enroll [USER]`

# Script for KDE fingerprint login #
This wont work after a relogin. This is caused by a blocking fprint and the fact, that we can't really detect the end of a session...
```
#!/bin/bash

# Create a locking directory to make sure this script can only run once at the time. Maybe add "-$USER" to allow multi users...
if mkdir /tmp/kscreensaver-fingerprint
then

    screenLocked=false
    failureCounter=0

    # Run as long the session exists...
    while :
    do
        # Check if the screensaver is running...
        if pgrep "kscreenlocker" > /dev/null # Add -s to only watch the own session
        then
            # Yes? Sleep (to allow the pc to enter standby and resume) then start the fingerprint
            if ! $screenLocked
            then
                sleep 2
            fi
            
            screenLocked=true
            echo "Screen locked!"

            string=$(fprintd-verify $USER)
            if [[ $string == *"verify-match"* ]]
            then
                # Order systemd to kill the lockscreen
                loginctl unlock-session
            else
                # Determine if we really failed or just fucked up...
                if [[ $string == *"verify-no-match"* ]]
                then
                    # Note the failure...
                    ((failureCounter++))
                    echo "MATCH FAILED -> increasing failureCounter"
                else
                    echo "fprintd-verify just fucked up..."
                fi
            fi
        else
            # No? Well, do nothing - except the screen was locked before...
            if $screenLocked
            then
                # ...then show the number of failed attempts.
                echo "Screen unlocked!"
                if [ $failureCounter -gt 0 ]
                then
                    # Add -t 20 to timeout; but this will hide the notification under some KDE/Plasma versions
                    # If the command is not known; try to install libnotify-bin
                    notify-send -i unlock "Failed fingerprint unlock attempts!" "There were $failureCounter failed attempts to unlock the screen by using the fingerprint." # Remove -t 20 to enable persistent notifications...
                fi
                failureCounter=0
            fi
            screenLocked=false
            #echo "Screen not locked."
        fi
ps x > /tmp/psEE
        sleep 1 # Check every second if the screen is locked...
    done
else
    echo "Args. Cant get locking dir. End of execution..."
fi
```
