---
summary: Let your server email yourself (useful for crontab, SMART, ...)
---

# Setup #
...on debian to send all emails received with `mail` by itself to the target.
Install `mailutils` and `exim4` (Both required!) and add desired target (maybe forward `root` to your own user) by adding
some lines like `[USERNAME]: [EMAIL]` to the following file:
```bash
sudo apt-get install mailutils exim4
sudo nano /etc/aliases
```

## Local email ##
1. Run `sudo dpkg-reconfigure exim4-config` and select `internet site` (confirm everything with return...)
2. Add `[USERNAME]` to the `mail` group: `sudo adduser [USERNAME] mail`
3. Enjoy you local email service!

## Email with remote SMTP server ##
_If you want to use this feature and don't need to authenticate against the SMTP server you should check the lighter `postfix` mailserver out._
1. Run `sudo dpkg-reconfigure exim4-config` and select `mail sent by smarthost; no local mail`
2. Enter at `IP address or host name of the outgoing smarthost` your smtp server like `[SMTP_SERVER_HOST]::[PORT_587]`
3. Add the credentials to the local config: `sudo nano /etc/exim4/passwd.client`: `[SMTP_SERVER_HOST]:[USERNAME]:[PASSWORD]`
4. Restart exim4 with `sudo systemctl restart exim4`
5. Test with: `mail -s [SUBJECT]` and CTRL-D

### Override `From`-Server domain ###
...just by filling out the fields at the `dpkg-reconfigure` command correctly an then enabling the option `Hide local mail name in outgoing mail?`
(the visible internal system name does matter, if you wish to still be able to distinct e.g. the `root`-user of two machines. Otherwise
their domain name will be replaced to the server name and in this case also the aliases won't work).
This ensures the domain name is corrected for every possible email-sending user - other than the following option, which allows the rewrite
only for specific users (so you must fix e.g. `root`, `netdata` and so on seperatly on evey machine)!

### Override `From`-Field completly ###
Some SMTP email servers really don't like freely choosen sender emails. To bypass this add a new line to the file like
`[USERNAME]: [NEW_FROM_EMAIL]`:
```bash
sudo nano /etc/email-addresses
```

# Something wrong? #
...or you don't get the sent emails? Send some emails manually with `mail -s [SUBJECT] [TARGET_EMAIL_OR_LOCAL_USERNAME]` and `CTRL-D`
and watch the logs with `sudo tail -f /var/log/exim4/mainlog` or `sudo tail -f /var/log/exim4/paniclog`...
