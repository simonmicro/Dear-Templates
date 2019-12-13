# NOTE / WARNING #
Some operations will need a lot power or disk space, so consult 'man borg' for detailed information!
Make sure to have at least 1G+ free disk space for larger archives (bigger repository means more free space needed)!
To disable backup deletion see: 'https://borgbackup.readthedocs.io/en/stable/usage/notes.html#append-only-mode'
* For example scripts [see](https://thomas-leister.de/server-backups-mit-borg/)
* For more information [see](https://wiki.ubuntuusers.de/BorgBackup/) or [see](https://borgbackup.readthedocs.io/en/stable/faq.html) or `man borg`

You can add to nearly to any command:
* `-s` Show statistics at finish
* `-p` Little information while working...

## LEGEND ##
* `TARGET` Means the folders path (sometimes mentioned as repository) or an ssh-connection-folder (e.g. `ssh://([USER]@)[IP(:PORT)]/~/[PATH_IN_USERDIR](/$HOSTNAME)`)
* `NAME` Means the archives name - maybe a `$(date)` is useful...
* `[?]` MUST filled
* `(?)` CAN filled


## BEGIN ##
Create a borg folder/repository
`borg init -e repokey TARGET`

* `-e [MODE]` Specifies the encryption; 'keyfile' is good (it will ask for the password every time) - you have the key under ~/.config/borg/keys/, 'repokey' is DANGEROUS WITHOUT PASSWORD (it will still ask for the password every time) - the key will be saved (with password encrypted) inside the repositories configuration, 'none' is... yeah...
* `--append-only` Prohibits deletion of archives
* `--storage-quota [QUOTA]` Set storage quota of the new repository (e.g. 5G, 1.5T) - usefull to make sure to be able to delete afterwards...

## BACKUP ##
Create an archive
`borg create -C none TARGET::NAME [NOW MULTIPLE FOLDERS TO INCLUDE]`

* `-C [MODE]` Sets compression level; `none` ~; `zlib` is medium speed and compression; `lzma` is slow but best; `zlib,[COMPRESSIONLEVEL]` and `lzma,[COMPRESSIONLEVEL]` are available too `[0,9]`
* `--lock-wait [SECONDS]` Maybe inside a script which fires multiple creations - to proccess the timeout on connection losses


### Commands... ###
* `borg check TARGET::NAME` Rechecks the archives integrity - useful to determine the size the dataloss after a drive failure
* `borg check --repair TARGET::NAME` ONLY IF NECCESSARY... THIS WILL MINIMIZE DATA LOSS ON DAMAGED FILES BUT NOT FIX
* `borg list TARGET` Lists all available archives
* `borg info TARGET::NAME` Archive information...
* `borg prune TARGET::NAME` Removes archive
* `borg prune TARGET --keep-daily=7 --keep-weekly=4 --keep-monthly=6 --keep-yearly 2` Cleans the repository up...
* `borg change-passphrase TARGET` Changes keyfiles password
* `borg mount TARGET::NAME [DIR]` Mounts the archive for easier operations...
* `borg umount [dir]` Unmounts the archive...
* `borg key export TARGET [PATH]` Backup the encryption key of the repository
* `borg key import TARGET [PATH]` Restores the encryption key of the repository (useful with keyfile encrytion)


### Useful... ###
* `export BORG_PASSPHRASE='[PASSWORD]'` Prevents the passwords request - BUT BE CAREFUL! THAT WILL BE SAVED E.G. TO THE BASH_HISTORY
* `export BORG_PASSCOMMAND='cat $HOME/.borg-passphrase'` Same as above, but reads the password e.g. from a file (or e.g. from zenity --password). '~' doesn't work.
* `export BORG_KEY_FILE='[KEYFILE_PATH]'` Specifies the path for the keyfile, if the key is stored locally (if not using the repokey)
* `export BORG_RSH='ssh -i [SSH_KEYFILE_PATH]'` Maybe neccessary, if ssh fails to authenticate automatically with the keyfiles under ~/.ssh
