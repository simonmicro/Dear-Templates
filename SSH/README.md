# HowTo SSH KeyAuth #
* use `ssh-keygen` on the client
* copy the content of the new clients .pub to servers `~/.ssh/authorized_keys`
* (maybe use `ssh-copy-id USER@HOST`)
* (client connects now with ssh [] -i KEYFILE_PATH) - should work without if KEYFILE is located under clients `~/.ssh/`
