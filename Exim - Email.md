---
summary: Let your server email yourself (useful for crontab, SMART, ...)
---

# Setup basic email #
...on debian to send all emails received with `mail` by itself to the target.
1. Install `mailutils` and `exim4` (Both required!): `sudo apt-get install mailutils exim4`
2. `sudo nano /etc/aliases`
3. Add desired target: `[USERNAME]: [EMAIL]`
4. Run `sudo dpkg-reconfigure exim4-config` and select `internet site` (confirm everything with return...)
5. Add `[USERNAME]` to the `mail` group: `sudo adduser [USERNAME] mail`
6. Enjoy you local email service!

# Setup email with remote SMTP server #
1. Run `sudo dpkg-reconfigure exim4-config` and select `mail sent by smarthost; received via SMTP or fetchmail`
2. Enter at `IP address or host name of the outgoing smarthost` your smtp server like `[SMTP_SERVER_HOST]::[PORT_587]`
3. Add the credentials to the local config: `sudo nano /etc/exim4/passwd.client`: `[SMTP_SERVER_HOST]:[USERNAME]:[PASSWORD]`
4. Restart exim4 with `sudo systemctl restart exim4`
5. Test with: `mail -s [SUBJECT]` and CTRL-D
