#!/bin/bash
# save (store ram and shutdown) all guests

cd /mnt/
echo "Working in `pwd`."
virsh list | `#list of running guest` \
tail -n +3 | head -n -1 | sed 's/\ \+/\t/g' | `#strip head and tail, use tab for seperator`\
awk '{print($2)}' | \
while read GUEST; do
    echo "Saving $GUEST..."
    virsh save $GUEST $GUEST.state
done
