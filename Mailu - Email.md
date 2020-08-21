---
summary: Manage your own email server easily - and how to setup servers to email you. And SPF and stuff...
---

# Install Mailu #
1. Generate the default pair of the `docker-compose.yml` and `mailu.env` files [here](https://setup.mailu.io/1.7/) - here some notes:
    * DO NOT USE IPv6 -> THIS CAUSES AN OPEN RELAY - REGARDLESS OF THE CONFIGURATION (see issue [here](https://github.com/Mailu/Mailu/issues/1578))
    * With DB (sqlite can be very slown with bigger systems) - why not?
    * Enable the Rainloop-webmail it is needed for sieve script editing (Mailu cant expose the sieve ports currently)
2. Add the initial administrator account with `docker-compose exec admin flask mailu admin USERNAME DOMAIN PASSWORD` (the email for the admin will be `USERNAME@DOMAIN`)
3. Disabled the POP3 ports and allowed them to listen on `0.0.0.0` - note I don't use ipv6 here!
4. Added a user forward wildcard (`%` - SQL syntax) to point to some account, this hides the known users on the system (no rejecting)
5. Maybe use relay hosts (authenticated SMTP is also supported) - otherwise your private ip address can lock you from some email providers out -> see https://mailu.io/master/configuration.html
6. Add the following to the webmail section inside the compose file to unlock the custom sieve script button inside the webmail (from [here](https://github.com/Mailu/Mailu/issues/1452)):
    ```
    command: ["bash", "-c", 'sed -i "/^sieve_allow_raw/s/=.*/= On/" /default.ini; /start.py']
    ```

# Configure Postfix and Servers #
Why Postfix? Because it is dead simple and we don't need any SMTP authentication for the trusted servers here...
1. Installed postfix
    * Satellite system
    * Relay host is the hostname of the Mailu server (make sure to use IPv4 when you enter a static ip address here)
2. Change `/etc/aliases` to point `root` to e.g. your user and your user to any email on the Mailu server
3. Apply the changes with `sudo newaliases`
4. Change inside `/etc/postfix/main.cf` file the `myhostname` to something like `hostname.localdomain` to fix senderaddress rejected - this can sometimes still fail. In that case allow the affected server ips as relay networks without authentication inside the `mailu.env` file (private ipv4s are not routed, therefore OK)...
5. Add DKIM, SPF and DMARC - this way you can make sure nobody could impersonate your domains email server (how it works see [here](https://www.youtube.com/watch?v=oEpU-iqBerI))!
6. Make it more secure (we don't need to forward emails from outside to our smtp server for which we are may whitelisted) - comment inside `/etc/postfix/master.cf` the following line:
    ```
    smtp      inet  n       -       y       -       -       smtpd
    ```

## Notes ##
* In case of errors with postfix: `sudo tail -f /var/log/mail.*`
* If you ever need the install configure assistant again: `sudo dpkg-reconfigure postfix`
* If you want to use postfix on the docker host itself, it will need an other port to talk to the front container of Mailu - add a port like this (instead of 25) -> `127.0.0.1:11823:25`. Otherwise postfix will think it would use itself to deliver emails - therefore block any email...
* If you are using an (offline) Mailu instance for local delivery, which replaces the 25 port on your machine, be aware that postfix will only respect a direct hit inside the `/etc/aliases` file. Any indirect hit (`netdata -> root -> user` won't be resolved, which may cause some problems).
