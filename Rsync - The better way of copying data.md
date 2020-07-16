---
summary: Just some commands and explanations, because I always forget them...
---

# The options #
```
-v increase verbosity
-a archive mode; equals -rlptgoD (no -H,-A,-X)
    recurse into directories
    preserve symlinks
    preserve permissions
    preserve modification times
    preserve group
    preserve owner (super-user only)
    same as --devices --specials
        preserve device files (super-user only)
        preserve special files
-r recurse into directories
-h output numbers in a human-readable format
-P same as --partial --progress
    keep partially transferred files
    show progress during transfer
-z compress file data during the transfer
--dry-run perform a trial run with no changes made
```

# Use cases #
Here some copy-to-paste examples...
You should not use `-z` on really low-end systems due its need for at least _some_ CPU power.

## Local: Just a better `cp` ##
```bash
rsync -zhvP
```

## Local: Preserve every metadata ##
```bash
rsync -zahvP
```

## How to remote ##
Just prepend a `[USER]@[HOST]:` before the source / target.

# The slash on directories #
_I. Forget. It. EVERY. TIME._ So here once and for all:

## No slash ##
Every the source dir **itself** will be copied **within** the destination dir.

## Destination slash ##
Same as no slash at all.

## Source slash ##
Every file **within** the source dir will be copied **within** the destination dir.

## Both slash ##
Same as source slash.
