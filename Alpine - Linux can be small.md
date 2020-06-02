---
summary: Just some trivial things, which need a special treatment under Alpine Linux.
---

# Set the default editor in Alpine Linux #
With `nano ~/.profile` add:
```
export EDITOR='nano'
export VISUAL='nano'
```

# Accept new SSH host key in Alpine Linux #
_The `-p` can be omitted but not moved inside the command!_
```
ssh-keyscan -H -p [PORT] [HOST] >> ~/.ssh/known_hosts
```
