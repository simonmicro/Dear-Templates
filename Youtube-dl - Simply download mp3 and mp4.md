---
summary: Bash alias to fastly download mp3 and mp4 from e.g. Youtube
---

# Setup #
Add the following to the `.bashrc` to enable your alias. The `downloadbest` alias always tries to get the really best format, but does not work all the times!
```bash
alias downloadmp3="~/.youtube-dl -x -i --prefer-ffmpeg --audio-format mp3 --embed-thumbnail"
alias downloadbestmp3="~/.youtube-dl -x -i --format "bestaudio/best" --prefer-ffmpeg --audio-format mp3 --embed-thumbnail"
alias downloadmp4="~/.youtube-dl -i --prefer-ffmpeg --format mp4 --embed-thumbnail"
alias downloadbestmp4="~/.youtube-dl --format "bestvideo+bestaudio[ext=m4a]/bestvideo+bestaudio/best" --merge-output-format mp4 --embed-thumbnail"
```

Add the following into your `crontab` to make sure the used binary is _always_ the latest version (updated at 14:00 every day) - this prevents strange errors after some time the binary was downloaded.
```
0 14 * * * bash -c "wget https://yt-dl.org/downloads/latest/youtube-dl -O $HOME/.youtube-dl && chmod +x $HOME/.youtube-dl"
```

You must install the following packages to ensure the downloaded files can be convterted to the required format.
```bash
sudo apt install ffmpeg
```

# Usage #
...just an example here:
```bash
downloadmp4 "https://www.youtube.com/watch?v=YE7VzlLtp-4"
```
