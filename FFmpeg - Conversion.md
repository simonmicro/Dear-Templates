---
summary: Some copy-paste scripts for mass media conversion
---

# Video
_Note:_ Without proper reencoding the filesize will stay the same and some devices still don't open the results - even if they support e.g. `mp4` - this does not mean they support the used codec. To fix this, please re-encode the files properly - this will take much more time, but provides better filesizes and results!

As `ffmpeg` is not always the most stable program, I recommend to use this script for conversion:
```python
import os, subprocess

# Config
inFolder = '.'
inExtensions = ['mkv', 'avi', 'mp4', 'flv', 'mov']
outFolder = './out'
outExtension = 'mkv' # If you change this, you must also change the ffmpeg command (e.g. if subtitles can't be preserved)
retries = 10
justCopy = False # Copy files without re-encoding

# Script
class Task:
    def __init__(self, inFile, outFile):
        self.inF = inFile
        self.out = outFile
        self.retries = retries
    
    def run(self) -> bool:
        if os.path.isfile(self.out):
            return True # Oh, we already finished that file
        if self.retries > 0:
            if justCopy:
                cmnd = ['ffmpeg', '-fflags', '+genpts', '-i', self.inF, '-codec', 'copy', self.out]
            else:
                cmnd = ['ffmpeg', '-i', self.inF, '-fflags', '+genpts', '-vcodec', 'libx265', '-crf', '28', '-map', '0', '-scodec', 'copy', '-acodec', 'copy', self.out]
            print('Running (' + str(self.retries) + '): ' + ' '.join(cmnd))
            res = subprocess.run(cmnd).returncode
            print('Done with code ' + str(res) + '...')
        else:
            return False
        if res == 0:
            return True
        else:
            self.retries -= 1
            return False

# Queue all files
queue = []

for path, dirs, files in os.walk(inFolder):
    if path.startswith(outFolder):
        continue
    for file in files:
        name, ext = os.path.splitext(file)
        ext = ext.lstrip('.')
        if ext.lower() in inExtensions:
            inFile = os.path.join(path, file)
            outFile = os.path.join(outFolder, name + '.' + outExtension)
            queue.append(Task(inFile, outFile))

# Run
os.makedirs(outFolder, exist_ok=True)
results = []

while len(queue):
    task = queue.pop(0)
    if task.run():
        results.append((True, task))
    else:
        try:
            os.remove(task.out)
        except:
            pass
        if task.retries > 0:
            queue.append(task)
            print('Retrying...')
        else:
            results.append((False, task))
    print(f'Progress: {len(queue)} remaining, {len(results)} processed')

# Print results
print()
for r in results:
    print(f'{"OK" if r[0] else "!!"}: {r[1].inF} -> {r[1].out}')
```

# Audio #

## Normalize
This normalizes to `0db` - NOTE that the parent folder is used since we don't change the audio format extension and therefore we would loop for a infinite time...
```bash
#!/bin/bash
set -xe
mkdir -p ../normalized/
for i in *.mp3;
    do name=`echo ${i%.*}`;
    echo $name;
    ffmpeg -i "$i" -af "volume=0dB" "../normalized/${name}.mp3";
    sleep 1
done
```

## FLAC to MP3
```bash
#!/bin/bash
set -xe
mkdir -p ./converted/
for i in *.flac;
    do name=`echo ${i%.*}`;
    ffmpeg -i "$i" -acodec libmp3lame "./converted/${name}.mp3";
    sleep 1
done
```
