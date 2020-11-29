---
summary: Remove unwanted characters from filenames
---

Some filenames may have some nasty utf8 characters in them (e.g. 'パッチ♥】→╭╯'), which may break some other devices...
Mass removal? There you go (for example):
```bash
rename -n 's/[→╭╯]//g' *
```
Remove `-n` whenever you feel ready...

Or when you not want to blacklist, use this whitelisting method (NO dryruns here!):
```bash
# The export enforces to use the right char sets...
export LC_ALL=C
# Remove any chars except...
for oname in *; do
    nname=`echo ${oname} | sed 's/[^a-zA-Z0-9\-\. ]//g'`;
    mv -v "${oname}" "${nname}";
done
# Strip leading space
for oname in *; do
    nname=`echo ${oname} | sed 's/ *$//g'`;
    mv -v "${oname}" "${nname}";
done
```
