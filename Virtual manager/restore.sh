#!/bin/bash
# restore all hosts from saved state (ram image) and start

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
