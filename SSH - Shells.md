---
summary: KeyAuth and sshd hardening
---

# HowTo SSH KeyAuth #
* use `ssh-keygen` on the client
* copy the content of the new clients .pub to servers `~/.ssh/authorized_keys`
* (maybe use `ssh-copy-id USER@HOST`)
* (client connects now with ssh [] -i KEYFILE_PATH) - should work without if KEYFILE is located under clients `~/.ssh/`

# Example config #
Located at `/etc/ssh/sshd_config`
APPEND or modify for more security and features...
```
# Automatic IDLE-Timeout after 30 minutes
ClientAliveInterval 1800
ClientAliveCountMax 0

# No empty passwords
PermitEmptyPasswords no

# No ROOT login
PermitRootLogin no

# For more security force protocol v2
Protocol 2

# Maybe run SSH on a non standard port
#Port 2025

# x11's SSH-Forward - it's a feature xP
X11Forwarding yes

# !!!DANGER!!! FORCE GROUP MEMBERSHIP (REQUIRES sudo addgroup sshuser before)
#AllowGroups sshuser

# Allow public key authentication see 'HowTo SSH KeyAuth'
#PubkeyAuthentication yes

# !!!DANGER!!! FORCE PUBLIC KEY AUTH FOR THIS MACHINE
#PasswordAuthentication no
```
