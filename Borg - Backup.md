---
summary: Notes regarding the borg backup system. Also a setup script for automated, encrypted, and deduplicated backups is included...
---

# Note
Some operations will need a lot power or disk space, so consult `man borg` for detailed information!
Make sure to have at least 1G+ free disk space for larger archives (bigger repository means more free space needed)!
To disable backup deletion see: 'https://borgbackup.readthedocs.io/en/stable/usage/notes.html#append-only-mode'
* For example scripts [see](https://thomas-leister.de/server-backups-mit-borg/)
* For more information [see](https://wiki.ubuntuusers.de/BorgBackup/) or [see](https://borgbackup.readthedocs.io/en/stable/faq.html) or `man borg`

You can add to nearly to any command:
* `-s` Show statistics at finish
* `-p` Little information while working...
* `--dry-run` Well, you know...

## Legend for this
* `TARGET` Means the folders path (sometimes mentioned as repository) or an ssh-connection-folder (e.g. `ssh://([USER]@)[IP(:PORT)]/~/[PATH_IN_USERDIR](/$HOSTNAME)`)
* `NAME` Means the archives name - maybe a `$(date)` is useful...
* `[?]` MUST filled
* `(?)` CAN filled

## Init repository
Create a borg folder/repository
`borg init -e repokey TARGET`

* `-e [MODE]` Specifies the encryption; 'keyfile' is good (it will ask for the password every time) - you have the key under ~/.config/borg/keys/, 'repokey' is DANGEROUS WITHOUT PASSWORD (it will still ask for the password every time) - the key will be saved (with password encrypted) inside the repositories configuration, 'none' is... yeah...
* `--append-only` Prohibits deletion of archives
* `--storage-quota [QUOTA]` Set storage quota of the new repository (e.g. 5G, 1.5T) - useful to make sure to be able to delete afterwards...

## First Backup
Create an archive
`borg create -C none TARGET::NAME [NOW MULTIPLE FOLDERS TO INCLUDE]`

* `-C [MODE]` Sets compression level; `none` ~; `zlib` is medium speed and compression; `lzma` is slow but best; `zlib,[COMPRESSIONLEVEL]` and `lzma,[COMPRESSIONLEVEL]` are available too `[0,9]`
* `--lock-wait [SECONDS]` Maybe inside a script which fires multiple creations - to proccess the timeout on connection losses

## Commands...
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
* `borg break-lock TARGET` In case borg cant finish the backup, you'll need to release the lock manually
* `borg extract TARGET::NAME [PATH]` Extracts the path from the archive to the current working directory


## Useful...
* `export BORG_PASSPHRASE='[PASSWORD]'` Prevents the passwords request - BUT BE CAREFUL! THAT WILL BE SAVED E.G. TO THE BASH_HISTORY
* `export BORG_PASSCOMMAND='cat $HOME/.borg-passphrase'` Same as above, but reads the password e.g. from a file (or e.g. from zenity --password). '~' doesn't work.
* `export BORG_KEY_FILE='[KEYFILE_PATH]'` Specifies the path for the keyfile, if the key is stored locally (if not using the repokey)
* `export BORG_RSH='ssh -i [SSH_KEYFILE_PATH]'` Maybe neccessary, if ssh fails to authenticate automatically with the keyfiles under ~/.ssh

# Universal backup script
The example is here `ssh://server/./subdir` - meaning a remote repository. If you plan to use a local solution, you may omit the SSH parts.
The script expects a folder called `backup_scripts` inside your home (you should run this as root anyways). Inside this folder you have to create a subfolder containing the backup target yaml-configuration (see below).
## Prepare the repository
Lets call this example repository `remote` located at `ssh://server/./subdir` (as noted before).
```bash
# Remote only: Create a new ssh key
ssh-keygen -q -N '' -a 4096 -f ~/backup_scripts/remote/SSHKey.pem
# Remote only: Prepare the ssh-env-vars for repository creation
export BORG_RSH='ssh -i ~/backup_scripts/remote/SSHKey.pem'
# Remote only: View the public key and MAKE SURE TO INSTALL IT NOW on the target server!
cat ~/backup_scripts/remote/SSHKey.pem.pub

# Create a new encryption key
openssl rand -base64 4096 > ~/backup_scripts/remote/BORGKeyPassword.file
# Prepare the env-vars for repository creation
export BORG_PASSPHRASE=`cat ~/backup_scripts/remote/BORGKeyPassword.file`
# Create the repo!
borg init -e keyfile ssh://server/./subdir
# And make sure to have a key backup!!!
borg key export ssh://server/./subdir ~/backup_scripts/remote/BORGKey.bak
```

## Prepare the config(s)
Put this into `~/backup_scripts/remote/config.yaml`:
```yaml
backup:
  - $HOME/backup_scripts/
target: 'ssh://server/./subdir'
options:
  backup: '-C lzma,9'
  cleanup: '--lock-wait 60'
cleanup:
  daily: 7
  weekly: 4
  monthly: 6
  yearly: 2
tries:
  backup: 3
  cleanup: 3
```

## Finally the script...
...place it somewhere into the home folder - just make sure only the user can read and execute it (`chmod 700`)!
```python
#!/usr/bin/python3
import os
import yaml
import time
import logging
import argparse
import subprocess
logger = logging.getLogger(__name__)

# Base variables
configDirPath = os.path.join(os.path.expanduser('~'), 'backup_scripts')

# Parse args
parser = argparse.ArgumentParser()
parser.add_argument('--config', help='Set the configuration directory name (located at ' + configDirPath + ').', type=str, required=True)
parser.add_argument('--shell', help='Execute a shell with all environment variables set.', action='store_true')
parser.add_argument('--debug', help='Debug mode!', action='store_true')
parser.add_argument('--nocreate', help='Skip archive creation.', action='store_true')
parser.add_argument('--nocleanup', help='Skip archive cleanup.', action='store_true')
parser.add_argument('--progress', help='Show progress...', action='store_true')
args = parser.parse_args()

if args.debug:
    logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.DEBUG)
else:
    logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

# Make sure config dir is available
configDirPath = os.path.join(configDirPath, args.config)
if not os.path.isdir(configDirPath):
    logger.critical('Config dir (' + configDirPath + ') not available!')
    exit(1)

# Read config vars
configFilePath = os.path.join(configDirPath, 'config.yaml')
if not os.path.isfile(configFilePath):
    logger.critical('Config file (' + configFilePath + ') not available!')
    exit(2)
with open(configFilePath, 'r') as configFile:
    configDict = yaml.safe_load(configFile)
configBackupThis = [os.path.expandvars(x) for x in configDict['backup']]
configBackupOptions = configDict['options']['backup'].split(' ') if configDict['options']['backup'] != '' else []
configCleanupOptions = configDict['options']['cleanup'].split(' ') if configDict['options']['cleanup'] != '' else []
if args.progress:
    configBackupOptions.append('-p')
    configCleanupOptions.append('-p')
if args.progress or args.debug:
    configBackupOptions.append('-v')
    configCleanupOptions.append('-v')

# Make sure every backup target exists
if not args.nocreate:
    for p in configBackupThis:
        if not os.path.exists(p):
            if not not args.shell:
                logger.warning('Backup path (' + p + ') not available!')
            else:
                logger.critical('Backup path (' + p + ') not available!')
                exit(3)

# Prepare environment variables
os.environ['THIS_TARGET'] = configDict['target']
targetIsRemote = configDict['target'].startswith('ssh://')
if targetIsRemote:
    sshKeyPath = os.path.join(configDirPath, 'SSHKey.pem')
    os.environ['BORG_RSH'] = 'ssh -i ' + sshKeyPath
    if not os.path.isfile(sshKeyPath):
        logger.critical('SSH key (' + sshKeyPath + ') not available!')
        exit(3)
os.environ['BORG_KEY_FILE'] = os.path.join(configDirPath, 'BORGKey.bak')
# I tried to load the file in the BORG_PASSPHRASE variable, but Python does not seem to handle new lines consistently (sometimes they are just becoming spaces)
os.environ['BORG_PASSCOMMAND'] = 'cat "' + os.path.join(configDirPath, 'BORGKeyPassword.file') + '"'
os.environ['BACKUP_THIS'] = ' '.join(configBackupThis)

# Should we fire of a shell?
if args.shell:
    logger.info('Following environment variables are set for you:')
    vars = ['THIS_TARGET', 'BORG_PASSCOMMAND', 'BACKUP_THIS', 'BORG_KEY_FILE']
    if targetIsRemote:
        vars.append('BORG_RSH')
    for v in sorted(vars):
        logger.info('\t' + v)
    logger.info('Try to execute "borg info $THIS_TARGET" to test the connection.')
    logger.info('Starting shell...')
    os.system(os.environ['SHELL'])
    logger.info('Bye!')
else:
    # Run other stuff - add your own backup commands here!

    # Note this: https://borgbackup.readthedocs.io/en/stable/internals/frontends.html
    # Therefore we are not importing borg here, but instead use the command line interface!
    def runBorgCommand(cmnd, tries):
        for tryNum in range(1, tries+1):
            logger.debug(cmnd)
            proc = subprocess.Popen(cmnd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            stdout, _ = proc.communicate()
            if proc.returncode != 0:
                # Whoops!
                logger.error('Something went wrong (try {} out of {}):'.format(tryNum, tries))
                logger.error(stdout)
                time.sleep(10)
            else:
                logger.debug(proc.returncode)
                logger.info(stdout)
                break
        if tryNum == tries:
            logger.error('Cleanup failed.')
        return tryNum != tries

    # Create new archive
    createOK = args.nocreate
    if not args.nocreate:
        cmnd = ['borg', 'create', '-s']
        cmnd += configBackupOptions
        cmnd += [configDict['target'] + '::' + str(time.time())]
        cmnd += configBackupThis
        logger.info('Backup started...')
        createOK = runBorgCommand(cmnd, configDict['tries']['backup'])

    # Cleanup
    cleanOK = args.nocleanup
    if not args.nocleanup:
        cmnd = ['borg', 'prune', '-s']
        cmnd += configCleanupOptions
        cmnd += [configDict['target'], '--keep-daily=' + str(configDict['cleanup']['daily']), '--keep-weekly=' + str(configDict['cleanup']['weekly']), '--keep-monthly=' + str(configDict['cleanup']['monthly']), '--keep-yearly=' + str(configDict['cleanup']['yearly'])]
        logger.info('Cleanup started...')
        cleanOK = runBorgCommand(cmnd, configDict['tries']['cleanup'])

    if createOK and cleanOK:
        logger.info('Jobs successful finished.')
    else:
        logger.warning('At least one job failed.')
```
The last lines should allow your Sieve-Filters to highlight any failed executions easily.

You should also make sure to install this script into your crontab (daily is recommended):
```crontab
0 2 * * * /usr/bin/python3 "$HOME/backup_scripts/backup.py" --config remote
```
