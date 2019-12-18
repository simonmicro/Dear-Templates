#!/bin/bash

# CONFIGURATION SECTION - ENTER HERE YOUR DESIRED VALUES
# Unique - useful for multiple scripts (e.g. local and dedicated remote)
export THIS_NAME="local_workshop"
# Following can be e.g. ssh://USER@USER.example.com:22/./$HOSTNAME or a local path
export THIS_TARGET="ssh:///mnt/backups"
# CONFIGURATION SECTION END

export THIS_TARGET_IS_REMOTE=false
if [[ $THIS_TARGET =~ ^ssh:\/\/* ]] ; then
    export THIS_TARGET_IS_REMOTE=true
fi

clear
echo "
    ____  ____  ____  __________  ___   ________ ____  ______ 
   / __ )/ __ \/ __ \/ ____/ __ )/   | / ____/ //_/ / / / __ \ 
  / __  / / / / /_/ / / __/ __  / /| |/ /   / ,< / / / / /_/ /
 / /_/ / /_/ / _, _/ /_/ / /_/ / ___ / /___/ /| / /_/ / ____/ 
/_____/\____/_/ |_|\____/_____/_/  |_\____/_/ |_\____/_/      
                                                              
              __                                _       __ 
   ________  / /___  ______     _______________(_)___  / /_
  / ___/ _ \/ __/ / / / __ \   / ___/ ___/ ___/ / __ \/ __/
 (__  )  __/ /_/ /_/ / /_/ /  (__  ) /__/ /  / / /_/ / /_  
/____/\___/\__/\__,_/ .___/  /____/\___/_/  /_/ .___/\__/  
                   /_/                       /_/           

It is recommended to use this as ROOT to ensure the correctness of the
permissions and completion of the backed up files! We'll save the keys,
passwords and scripts to ~/backup_scripts/"$THIS_NAME"."
echo "BORGBACKUPs target is '"$THIS_TARGET"' - it is..."
if $THIS_TARGET_IS_REMOTE; then
    echo "...REMOTE so ssh keys will configured too..."
else
    echo "...local."
fi

echo "Make sure this is correct! HIT CTRL-C NOW TO ABORT! This is your only
and last chance to correct this values. To do that simply edit the
scripts source..."
echo "Press return to continue..."
read

echo "****Creating backup script folders..."
mkdir -p ~/backup_scripts/$THIS_NAME
if $THIS_TARGET_IS_REMOTE; then
    echo "****Generating a SSH key without a password"
    ssh-keygen -q -N "" -a 4096 -f ~/backup_scripts/$THIS_NAME/SSHKey.pem
    echo "!!!!Add this to your .ssh/authorized_keys file NOW:"
    cat ~/backup_scripts/$THIS_NAME/SSHKey.pem.pub
    echo "Press return to continue..."
    read
fi
echo "****Generating random passphare for the repository key..."
openssl rand -base64 4096 > ~/backup_scripts/$THIS_NAME/BORGKeyPassword.file


echo "****Setting vars up..."
export BORG_PASSPHRASE=`cat ~/backup_scripts/$THIS_NAME/BORGKeyPassword.file`
if $THIS_TARGET_IS_REMOTE; then
    echo "****Setting vars up - overwriting ssh command to allow publicKeyFileAuthentication..."
    export BORG_RSH='ssh -i ~/backup_scripts/'$THIS_NAME'/SSHKey.pem'
fi

echo "****Setting BORGBACKUP up..."
borg init -e keyfile $THIS_TARGET

echo "****Backing the encryption key up to ~/backup_scripts/$THIS_NAME/BORGKey.bak..."
echo "!!!!MOVE THIS FILE TO A SECURE PLACE NOW - IF YOUR DEVICE FAILS ANY DATA WILL BE LOST WITHOUT!"
borg key export $THIS_TARGET ~/backup_scripts/$THIS_NAME/BORGKey.bak

echo "****Writing header to the backup script..."
echo "#!/bin/bash" > ~/backup_scripts/$THIS_NAME/backup.sh
echo "THIS_TARGET='"$THIS_TARGET"'" >> ~/backup_scripts/$THIS_NAME/backup.sh
echo "THIS_NAME='"$THIS_NAME"'" >> ~/backup_scripts/$THIS_NAME/backup.sh
if $THIS_TARGET_IS_REMOTE; then
    echo "export BORG_RSH='ssh -i ~/backup_scripts/"$THIS_NAME"/SSHKey.pem'" >> ~/backup_scripts/$THIS_NAME/backup.sh
fi
echo "export BORG_PASSPHRASE=\`cat ~/backup_scripts/$THIS_NAME/BORGKeyPassword.file\`" >> ~/backup_scripts/$THIS_NAME/backup.sh

cat << EOF >> ~/backup_scripts/$THIS_NAME/backup.sh

# CONFIGURATION BEGIN
BACKUP_THIS="$HOME/backup_scripts/ "
BACKUP_OPTIONS='-C lzma' # Enable strong compression by default
CLEANUP_OPTIONS='--lock-wait 60' # Wait one minute to get the lock...
# CONFIGURATION END

# Enable the test mode if an argument is existent (enables progress info)
if ! [[ -z "\$1" ]]; then
        echo "TEST MODE IS ENABLED!"
        BACKUP_OPTIONS="-p -v \$BACKUP_OPTIONS"
        CLEANUP_OPTIONS="-p -v \$CLEANUP_OPTIONS"
fi

echo "THIS_NAME '"\$THIS_NAME"';
THIS_TARGET '"\$THIS_TARGET"';
BACKUP_THIS '"\$BACKUP_THIS"';
BACKUP_OPTIONS '"\$BACKUP_OPTIONS"';
CLEANUP_OPTIONS '"\$CLEANUP_OPTIONS"';
BORG_RSH '"\$BORG_RSH"';"

# Do some work here... Maybe export the SQL-databse or so...
#echo "MYSQL-DUMP started at \$(date)..."
#mysqldump -u USER -pPASSWORD --all-databases --skip-lock-tables > /tmp/databaseExport.sql
#echo "MYSQL-DUMP finished at \$(date)..."


# Now execute the backup (add -p to show progress while working; -s show a resumé at the end)
echo "Backup started at \$(date)..."
borg create -s \$BACKUP_OPTIONS "\$THIS_TARGET"::\$(date +"%s") \$BACKUP_THIS
echo "Backup finished at \$(date)."

echo "Cleanup started at \$(date)..."
borg prune -s \$CLEANUP_OPTIONS "\$THIS_TARGET" --keep-daily=7 --keep-weekly=4 --keep-monthly=6 --keep-yearly=2
echo "Cleanup finished at \$(date)..."

# Clean the varibales...
unset THIS_TARGET
unset THIS_NAME
unset BORG_PASSPHRASE
EOF


echo "!!!!Okay almost done yet. You will now get a chance to edit the backup.sh script."
echo "Press return to continue..."
read
nano ~/backup_scripts/$THIS_NAME/backup.sh

echo "****Installing the script to the daily crontab..."
(crontab -l ; echo "@daily /bin/bash \"\$HOME/backup_scripts/"$THIS_NAME"/backup.sh\"") | crontab -

echo "****Locking new folders down..."
chmod 500 ~/backup_scripts/$THIS_NAME/
chmod 400 -R ~/backup_scripts/$THIS_NAME/*

echo "****Allowing scripts execution..."
chmod +x ~/backup_scripts/$THIS_NAME/backup.sh
