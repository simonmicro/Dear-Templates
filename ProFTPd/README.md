# INSTALL #
* `sudo apt install proftpd-basic`
* `sudo addgroup ftpuser`

# INSTALL:SSL/TLS #
Cert should be added with following, so the config can use it...

`sudo openssl req -new -x509 -days 999 -nodes -out /etc/proftpd/proftpd.cert.pem -keyout /etc/proftpd/proftpd.key.pem`

# ADD USER #
1. `sudo adduser --no-create-home --shell /bin/nologin [USERNAME]`
2. `sudo addgroup [USERNAME] ftpuser`
3. `sudo usermod -d /var/www/ [USERNAME]`

# REMOVE USER #
`sudo deluser [USERNAME]`
