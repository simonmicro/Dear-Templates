---
title: FFmpeg
summary: Some copy-paste scripts for mass conversion
type: blog
banner: "/img/dear-templates/default.jpg"
---

# Video #

## AVI to MP4 ##

### Fast (without reencode) ###
This just copies the data without proper reencoding - some devices don't like the results...
```
#!/bin/bash
mkdir -p ./converted/
for i in *.avi;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    # Using the pts has no value fix...
    ffmpeg -fflags +genpts -i "$i" -codec copy "./converted/${name}.mp4";
    sleep 1
done
```

## MKV to MP4 ##
```
#!/bin/bash
mkdir -p ./converted/
for i in *.mkv;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    ffmpeg -i "$i" "./converted/${name}.mp4";
    sleep 1
done
```

### Fast (without reencode) ###
This just copies the data without proper reencoding - some devices don't like the results...
```
#!/bin/bash
mkdir -p ./converted/
for i in *.mkv;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    ffmpeg -i "$i" -codec copy "./converted/${name}.mp4";
    sleep 1
done
```

# Audio #

## Normalize ##
This normalizes to 0db - NOTE that the parent folder is used since we dont change the audio format and therefore we would loop for a infinite time...
```
#!/bin/bash
mkdir -p ../normalized/
for i in *.mp3;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    ffmpeg -i "$i" -af "volume=0dB" "../normalized/${name}.mp3";
    sleep 1
done
```

## FLAC to MP3 ##
```
#!/bin/bash
mkdir -p ./converted/
for i in *.flac;
    do name=`echo $i | cut -d'.' -f1`;
    ffmpeg -i "$i" -acodec libmp3lame "./converted/${name}.mp3";
    sleep 1
done
```
