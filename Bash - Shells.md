---
summary: Interactive bash sessions in the background with pipe access
---

# The command itself #
```
mkdir -p /tmp/[SESSION_NAME]/; mkfifo /tmp/[SESSION_NAME]/IN; nohup bash -c "while [ -e /tmp/[SESSION_NAME]/IN ]; do cat /tmp/[SESSION_NAME]/IN; sleep 0.4; done | bash -c \"echo \$ > /tmp/[SESSION_NAME]/PID; [SESSION_COMMAND]; echo \"End\" > /tmp/[SESSION_NAME]/IN; rm /tmp/[SESSION_NAME]/IN\"" > /tmp/[SESSION_NAME]/OUT 2>&1 </dev/null &
```
Make sure to fill in the following placeholders!
* `[SESSION_NAME]` An unique name of the session - maybe use `uuidgen`.
* `[SESSION_COMMAND]` The command to run inside the session.

## Usage ##
The above command will create a new folder on `/tmp/[SESSION_NAME]/` with a pipes `IN` and a file `OUT` in it.
You can e.g. pipe a command into the session with `echo "help" >> /tmp/[SESSION_NAME]/IN` (example if session is running a bash) and receive the result by reading the `/tmp/[SESSION_NAME]/OUT` file.
To constanty monitor the result use e.g. `tail -f /tmp/[SESSION_NAME]/OUT`.
Also a file called `PID` is created, containing the process id of the parent bash - this is to detect whether the session is still alive.

## How it works ##

Lets go over the command and look at every detail of it:
* `mkdir -p /tmp/[SESSION_NAME]/; mkfifo /tmp/[SESSION_NAME]/IN;` Prepare the folder for the session and also create the input pipe.
* `nohup bash -c "..." > /tmp/[SESSION_NAME]/OUT` Create the parent bach and pipe the output to the file...
    * `while [ -e /tmp/[SESSION_NAME]/IN ]; do cat /tmp/[SESSION_NAME]/IN; sleep 0.4; done ...` Try to read the pipe and only echo the line if it is completed with a newline char `\n`.
    * `... | bash -c \"echo \$ > /tmp/[SESSION_NAME]/PID; [SESSION_COMMAND]; echo \"End\" > /tmp/[SESSION_NAME]/IN; rm /tmp/[SESSION_NAME]/IN\"`
        1. Put the parents bash PID into the sessions folder...
        2. Take the input of the command before and pipe it into the executed session command.
        3. Just output one more line, so the while loop gets unblocked and the `cat` command ends...
        4. Remove the input pipe (signal for `while` to end, also makes sure no program could freeze, because it tries to write into a dangling pipe).

### Possible upgrades ###
* Move name and the command into variables, so they can be requested or updated on-the-fly...
