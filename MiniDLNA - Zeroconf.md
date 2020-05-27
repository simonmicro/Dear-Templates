---
summary: Notes how to setup and use Looking Glass
---

# Note #
Take a look into the minidlna.conf file (you'll be able to view the status of the minidlna server at the port 8200)!
Maybe you should add a cronjob to rescan the network attached folders every midnight by restarting the server...
```
0 4 * * * systemctl restart minidlna
```

# Example config #
```
# This file is located at /et/minidlna.conf

# If you want to restrict a media_dir to a specific content type, you can
# prepend the directory name with a letter representing the type (A, P or V),
# followed by a comma, as so:
#   * "A" for audio    (eg. media_dir=A,/var/lib/minidlna/music)
#   * "P" for pictures (eg. media_dir=P,/var/lib/minidlna/pictures)
#   * "V" for video    (eg. media_dir=V,/var/lib/minidlna/videos)
#   * "PV" for pictures and video (eg. media_dir=PV,/var/lib/minidlna/digital_camera)
media_dir=/mnt/BigFuckingHDD/Public
#media_dir=A,/mnt/BigFuckingHDD/Music
#media_dir=V,/mnt/BigFuckingHDD/Videos

# URL presented to clients (e.g. http://example.com:80).
presentation_url=http://example.com

# Name that the DLNA server presents to clients.
# Defaults to "hostname: username".
friendly_name=miniDLNA

# Use a different container as the root of the directory tree presented to
# clients. The possible values are:
#   * "." - standard container
#   * "B" - "Browse Directory"
#   * "M" - "Music"
#   * "P" - "Pictures"
#   * "V" - "Video"
#   * Or, you can specify the ObjectID of your desired root container
#     (eg. 1$F for Music/Playlists)
# If you specify "B" and the client device is audio-only then "Music/Folders"
# will be used as root.
root_container=.

# Path to the directory that should hold the log file.
#log_dir=/var/log

# The default is to log all types of messages at the "warn" level.
#log_level=general,artwork,database,inotify,scanner,metadata,http,ssdp,tivo=warn

# Path to the directory that should hold the database and album art cache. - /tmp -> rescan on every reboot
db_dir=/tmp/minidlna

# Port number for HTTP traffic (descriptions, SOAP, media transfer).
# This option is mandatory (or it must be specified on the command-line using
# "-p").
port=8200

# Specify the user name or uid to run as.
user=minidlna
group=minidlna

# This option can be specified more than once.
#network_interface=eth0,wlan0

# Serial number the server reports to clients.
# Defaults to 00000000.
#serial=681019810597110

# Model name the server reports to clients.
#model_name=Windows Media Connect compatible (MiniDLNA)

# Model number the server reports to clients.
# Defaults to the version number of minidlna.
#model_number=

# Automatic discovery of new files in the media_dir directory.
# Maybe increase the inotify limit:
# echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
# sudo sysctl -p
inotify=yes

# List of file names to look for when searching for album art.
# Names should be delimited with a forward slash ("/").
# This option can be specified more than once.
album_art_names=Cover.jpg/cover.jpg/AlbumArtSmall.jpg/albumartsmall.jpg
album_art_names=AlbumArt.jpg/albumart.jpg/Album.jpg/album.jpg
album_art_names=Folder.jpg/folder.jpg/Thumb.jpg/thumb.jpg

# Strictly adhere to DLNA standards.
# This allows server-side downscaling of very large JPEG images, which may
# decrease JPEG serving performance on (at least) Sony DLNA products.
#strict_dlna=no

# Support for streaming .jpg and .mp3 files to a TiVo supporting HMO.
enable_tivo=yes

# Notify interval, in seconds.
#notify_interval=895

# Path to the MiniSSDPd socket, for MiniSSDPd support.
#minissdpdsocket=/run/minissdpd.sock

# Always set SortCriteria to this value, regardless of the SortCriteria
# passed by the client
# e.g. force_sort_criteria=+upnp:class,+upnp:originalTrackNumber,+dc:title
#force_sort_criteria=

# maximum number of simultaneous connections
# note: many clients open several simultaneous connections while streaming
#max_connections=50

# Set this to merge all media_dir base contents into the root container (so the browse dir don't show the last folder name of every path and just handels everything as one)
merge_media_dirs=yes
```

# Startup rescan service #
Caused by the delayed start of virtualbox, minidlna will scan at startup an empty folder. To fix this, restart minidlna right after the vbox service (for the shared folders) to trigger a rescan...
```
# Add it under /etc/systemd/system/minidlna_vbox_fix.service
# Enable it with "systemctl enable minidlna_vbox_fix"

[Unit]
Description=Restarts minidlna after virtualbox shared folders are available
After=vboxadd.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c "systemctl restart minidlna.service"

[Install]
WantedBy=multi-user.target
```
