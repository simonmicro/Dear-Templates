#!/bin/bash
# This normalizes to 0db NOTE that the parent folder is used since we dont change the audio format...
mkdir -p ../normalized/
for i in *.mp3;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    ffmpeg -i "$i" -af "volume=0dB" "../normalized/${name}.mp3";
    sleep 1
done
