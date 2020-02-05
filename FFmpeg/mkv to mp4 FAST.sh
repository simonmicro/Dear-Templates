#!/bin/bash
# This just copies the Data without proper reencoding - some devices don't like the results...
mkdir -p ./converted/
for i in *.mkv;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    ffmpeg -i "$i" -codec copy "./converted/${name}.mp4";
    sleep 1
done
