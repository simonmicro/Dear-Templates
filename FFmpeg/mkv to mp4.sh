#!/bin/bash
mkdir -p ./converted/
for i in *.mkv;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    ffmpeg -i "$i" "./converted/${name}.mp4";
    sleep 1
done
