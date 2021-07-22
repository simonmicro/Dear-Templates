---
summary: Manage as many Linux machines as you want. Simultaneously. Repeatable. Consistent.
---

# Master
## Install
```bash
sudo apt install ansible
```
Done.

_A word of warning beforehand:_ Try to use your local Ansible setup and NOT the global files like the one under `/etc/ansible/hosts`. This is just to prevent you from running everything with `root` 24/7!

## Create an ansible ssh-key
Create the key with `ssh-keygen` (running from your home directory and therefore set the path to `.ssh/ansible`). Edit `~/.ansible.cfg` and set `private_key_file` to the path from before.

You install the key by using (**NEVER EVER install this key into your root user**, for security reasons):
```bash
ssh-copy-id -i ~/.ssh/ansible [TARGET_USER]@[TARGET_HOST]
```
Then test it with:
```bash
ssh ~/.ssh/ansible [TARGET_USER]@[TARGET_HOST]
```
And you can always use the jump-host configuration as shown below:
```bash
ssh-copy-id -i ~/.ssh/ansible -o ProxyCommand="ssh -i ~/.ssh/ansible -W %h:%p [JUMP_USER]@[JUMP_HOST]" [TARGET_USER]@[TARGET_HOST]
ssh ~/.ssh/ansible -o ProxyCommand="ssh -i ~/.ssh/ansible -W %h:%p [JUMP_USER]@[JUMP_HOST]" [TARGET_USER]@[TARGET_HOST]
```

_Why not use `-J` for the `JumpHost` configuration?_ This option is new and does not inherit any further parameters from the parent process (like `-i`). It can be really useful in other scenarios, but not for Ansible (right now).

## Setup your users inventory
Add this to your `.bashrc` (only if you wish to use a local inventory):
```bash
export ANSIBLE_INVENTORY=$HOME/ansible/hosts
```
Now create the hosts file as following...

## Register hosts
Edit `~/ansible/hosts` (take a note at the excellent documentation in `/etc/ansible/hosts` and [there](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)) and...

* **add** some **hosts** (at the top):
    ```ini
    foo.example.com
    bar.example.com
    ```
* **define** a new **group** of hosts:
    ```ini
    [servergroupname]
    one.example.com
    two.example.com
    ```
* **define** a **ip** variable for a specific **host**:
    ```ini
    three.example.com ansible_host=[HOST_IP]
    ```
* **define** a **username & key** variable for a specific **host**:
    ```ini
    four.example.com ansible_user=[USER] ansible_ssh_private_key_file=/some/other/ssh/key
    ```
* **define** a **ssh-jump** variable for a specific **host** (the `ProxyCommand` will be executed as the ansible user -> make sure the ansible user can access his own key, also you may omit the `StrictHostKeyChecking` later on):
    ```ini
    five.example.com ansible_ssh_command_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ~/.ssh/ansible -W %h:%p -q [JUMP_HOST_USER]@[JUMP_HOST_URL]"'
    ```
* **define** **any variable** for a specific host **group**:
    ```ini
    [servergroupname:vars]
    ansible_user=[USER]
    ansible_ssh_private_key_file=/some/other/ssh/key
    ```
* **define** **any variable** for any **host** (this one variable is needed for newer installations, as the classic `/bin/python` path won't work anymore!):
    ```ini
    [all:vars]
    ansible_python_interpreter=/usr/bin/python3
    ```

# Test your connections
```bash
ansible all -m ping
```
_You'll may need to use `sudo`, if the key was created inside the configuration directory._
Instead of `all` you could also use any other configured group name like `servergroupname` from before.

# Running arbitrary commands
```bash
ansible all -a "uname -a"
```

## As root with password
```bash
ansible all -a "uname -a" --become --ask-become-pass
```

# Define a Playbook
Create a new `playbook.yml` and fill it (I would recommend to create it under `~/ansible/playbooks`):
```yaml
---
- name: Playbook Demo
  hosts: all
  become: false

  tasks:
  - name: Receive hostnames
    command: hostname
  - name: Show uname
    command: uname -a
    register: out
  - debug: var=out.stdout_lines
```
_The `debug` task will show the output variable - meaning the output of the module `command`._

Run it:
```bash
ansible-playbook playbook.yaml
```

## Install & remove some SSH keys
```yaml
---
- name: SSH Key Demo
  hosts: all

  tasks:
  - name: Make sure the ansible key is there
    authorized_key:
      user: "{{ ansible_user }}"
      state: present
      key: "{{ lookup('file', '/etc/ansible/ssh_key.pub') }}"
  - name: Remove an untrusted (old) key
    authorized_key:
      user: "{{ ansible_user }}"
      state: absent
      key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdOa2rCfsP6JtwMoO+3c10NgaPLasd7WA5yeYrdd5dJAmQOoHE0RL40POCd4zvq3k/8ehJ3DLcIkfcul6xj234ik2l/4lYHXMGas6Sz/VVvSjs4sfhlVkRm0cZIBXePjp5RNXPKZEtJih0D9aZEZOQ3dqOBloaPqzB2bkB1eF9lVlSLRl3NFF8xHh8vb7Il2+nqz4cvkq1XS1223aaXfNfQEJcuyk6ryAjtP8/y2oPuUlFY876YWbxd7Ct3xcGgpxVNS9ewlHBox9PKCtvK3g8DZvI2byB7bIT3nfcOrjkfA/ZP1WFGobOs/OGpb8Sh4I/Kq8fOu1MIHoaElQ/ngHBmD7I/o8PRutKIaC8c5sr3r3B10aJXkV2IHIzj08Qg8QCjJVj05/TcVg5ANkr6xy/mdSj1OOpfHW2Fk+xSj9xWSVRWxm0KOY5/7UMDfo1HjBW79xTIgk2Wa4Lx3pA6pxrv3yMX3XWhKF8oilA6QfsVLqNwElsK/Wk8XMgK2ulCojPoU= bad@key"
```
The `authorized_key`-module - what is that?! When you are unsure what Ansible can do for you - [try the documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html).

## Install some applications
```yaml
---
- name: APT Demo
  hosts: all
  become: true

  tasks:
  - name: Install THE BEST console text editor
    apt:
      name: nano
      state: present
```
_Make sure to run this one with `--ask-become-pass`, as `apt` can only be used as root!_

## Replay a stuck playbook
Just run (the `.retry` file will be automatically created):
```bash
ansible-playbook playbook.yml --limit @playbook.retry
```

### The automatic way
```python
import os
import re
import glob
import logging
import argparse
import subprocess

"""
Run this by using crontab - should be silent if everything is unreachable, otherwise it will show outputs!
Example need? Try that:
*/10 * * * * cd $HOME/ansible && python3 ./autoretry.py
...also ensure that crontab is sending you the commands output as e.g. email!
"""

parser = argparse.ArgumentParser()
parser.add_argument('-d', '--debug', action='store_true', help='Show debug msgs')
if parser.parse_args().debug:
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.INFO)

logger = logging.getLogger(__name__)
files = glob.glob('./**/*.retry', recursive=True)
for playbookRetry in files:
    # Setup vars
    playbookPath = os.path.split(playbookRetry)
    playbookExt = os.path.splitext(playbookPath[1])
    playbookYml = os.path.join(playbookPath[0], playbookExt[0] + '.yml')
    logger.debug(playbookPath[0])
    logger.debug(playbookYml)
    logger.debug(playbookRetry)

    # Execute the playbook
    if not os.path.isfile(playbookYml):
        logger.warning('Playbook src for retry not found!')
        continue
    try:
        # Yes, subprocess is bad - but the ansible python api is the worst. This works. Even using different versions. The api? Not.
        res = subprocess.run(['ansible-playbook', playbookYml, '--limit', '@' + os.path.join(playbookPath[0], playbookExt[0] + '.retry')],
            capture_output=True, cwd=os.getcwd(), timeout=60*60*2) # Timeout after 2 hours
    except subprocess.TimeoutExpired:
        logger.error('2h timeout on command execution')
        continue

    # Check if anything was successful or if we completed all
    lines = res.stdout.decode().split('\n')
    doneSmth = False
    unreachSmth = False
    for l in lines:
        if re.match(r'.+:.+ok=.+changed=.+unreachable=0.+failed=.+', l):
            doneSmth = True
        if re.match(r'.+:.+ok=.+changed=.+unreachable=1.+failed=.+', l):
            unreachSmth = True

    # Show logs on success or failures
    for l in lines:
        l = l.strip()
        if len(l) == 0:
            continue
        if doneSmth:
            logger.info(l)
        else:
            logger.debug(l)
    # ...else: Done nothing. Try again later...
    logger.debug('doneSmth ' + str(doneSmth))
    logger.debug('unreachSmth ' + str(unreachSmth))

    if not unreachSmth:
        logger.info('All plays finished. Removing retry file!')
        os.remove(playbookRetry)
```
_Enjoy._