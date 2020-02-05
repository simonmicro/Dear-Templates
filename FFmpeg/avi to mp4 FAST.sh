#!/bin/bash
# This just copies the Data without proper reencoding - some devices don't like the results...
mkdir -p ./converted/
for i in *.avi;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    # Using the pts has no value fix...
    ffmpeg -fflags +genpts -i "$i" -codec copy "./converted/${name}.mp4";
    sleep 1
done
