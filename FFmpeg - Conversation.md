---
summary: Some copy-paste scripts for mass media conversion
---

# Video #
_Note:_ Without proper reencoding the filesize will stay the same and some devices still don't open the results - even if they support e.g. mp4 - this does not mean they support the used codec. To fix this, please reencode the files - this will take much more time, but provides better filesizes and results!

## MP4 to MP4 ##
This just reencodes the files (reduce size)...
```bash
#!/bin/bash
mkdir -p ../reencoded/
for i in *.mp4;
    do name=`echo ${i%.*}`;
    echo $name;
    # Using the pts has no value fix...
    ffmpeg -fflags +genpts -i "$i" -vcodec libx265 -crf 28 "../reencoded/${name}.mp4";
    sleep 1
done
```

## MKV to MKV ##
This just reencodes the files (reduce size) - same as for mp4 (but keeps all audio tracks and subtitle metadata)!
```bash
#!/bin/bash
mkdir -p ../reencoded/
for i in *.mkv;
    do name=`echo ${i%.*}`;
    echo $name;
    # Using the pts has no value fix...
    ffmpeg -fflags +genpts -i "$i" -vcodec libx265 -crf 28 -map 0 -scodec copy -acodec copy "../reencoded/${name}.mkv";
    sleep 1
done
```

## AVI to MP4 ##

### Fast (without reencode) ###
This just copies the data without proper reencoding - some devices don't like the results...
```bash
#!/bin/bash
mkdir -p ./converted/
for i in *.avi;
    do name=`echo ${i%.*}`;
    echo $name;
    # Using the pts has no value fix...
    ffmpeg -fflags +genpts -i "$i" -codec copy "./converted/${name}.mp4";
    sleep 1
done
```

## MKV to MP4 ##
```bash
#!/bin/bash
mkdir -p ./converted/
for i in *.mkv;
    do name=`echo ${i%.*}`;
    echo $name;
    ffmpeg -i "$i" "./converted/${name}.mp4";
    sleep 1
done
```

### Fast (without reencode) ###
This just copies the data without proper reencoding - some devices don't like the results...
```bash
#!/bin/bash
mkdir -p ./converted/
for i in *.mkv;
    do name=`echo ${i%.*}`;
    echo $name;
    ffmpeg -i "$i" -codec copy "./converted/${name}.mp4";
    sleep 1
done
```

# Audio #

## Normalize ##
This normalizes to 0db - NOTE that the parent folder is used since we dont change the audio format and therefore we would loop for a infinite time...
```bash
#!/bin/bash
mkdir -p ../normalized/
for i in *.mp3;
    do name=`echo ${i%.*}`;
    echo $name;
    ffmpeg -i "$i" -af "volume=0dB" "../normalized/${name}.mp3";
    sleep 1
done
```

## FLAC to MP3 ##
```bash
#!/bin/bash
mkdir -p ./converted/
for i in *.flac;
    do name=`echo ${i%.*}`;
    ffmpeg -i "$i" -acodec libmp3lame "./converted/${name}.mp3";
    sleep 1
done
```
