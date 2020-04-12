---
title: Bash
summary: Interactive bash shells in background with pipe access
type: blog
banner: "/img/dear-templates/default.jpg"
---

# The ultimative... #
...command to send an interactive bash shell into the background:
```
nohup bash -c "cd ~/[WORKDIR]; echo $$ > /tmp/PID; [INTERACTIVE_SERVER_CMD] << /tmp/IN" > /tmp/OUT 2>&1
nohup bash -c "cd ~/[WORKDIR]; echo $$ > /tmp/PID; [INTERACTIVE_SERVER_CMD] > /tmp/OUT 2>&1 << /tmp/IN"

```
...or upgrade!
1. `mkfifo /tmp/IN`
2. `nohup bash -c "cd ~/[WORKDIR]; echo $$ > /tmp/PID; while true; do cat /tmp/IN; done | [INTERACTIVE_SERVER_CMD]" > /tmp/OUT 2>&1`
```
mkdir -p /tmp/[RUNNAME]; mkdir -p /tmp/[RUNNAME]/[ID]; mkfifo /tmp/[RUNNAME]/[ID]/IN; nohup bash -c "cd ~/[WORKDIR]; echo $$ > /tmp/[RUNNAME]/[ID]/PID; while true; do cat /tmp/[RUNNAME]/[ID]/IN; done | [INTERACTIVE_SERVER_CMD];" > /tmp/lWi/1/OUT 2>&1
```
...or FINAL upgrade!
```
bash -c 'mkdir -p /tmp/[RUNNAME]; mkfifo /tmp/[RUNNAME]/IN; nohup bash -c "cd ~/[WORK_DIR]; while [ -e /tmp/[RUNNAME]/IN ]; do cat /tmp/[RUNNAME]/IN; sleep 0.4; done | bash -c \"echo \$$ > /tmp/[RUNNAME]/PID; [COMMAND]; echo \"End\" > /tmp/[RUNNAME]/IN; rm /tmp/[RUNNAME]/IN\"" > /tmp/[RUNNAME]/OUT 2>&1 </dev/null &'
```
