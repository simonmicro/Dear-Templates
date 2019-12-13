#!/bin/bash
mkdir -p ./converted/
for i in *.flac;
    do name=`echo $i | cut -d'.' -f1`;
    ffmpeg -i "$i" -acodec libmp3lame "./converted/${name}.mp3";
    sleep 1
done


