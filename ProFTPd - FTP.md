---
summary: Setup with SSL for encryptet credentials and special umasks
---

# INSTALL #
```bash
sudo apt install proftpd-basic
sudo addgroup ftpuser
```

# INSTALL:SSL/TLS #
Cert should be added with following, so the config can use it...
```bash
sudo openssl req -new -x509 -days 999 -nodes -out /etc/proftpd/proftpd.cert.pem -keyout /etc/proftpd/proftpd.key.pem
```

# ADD USER #
```bash
sudo adduser --no-create-home --shell /bin/nologin [USERNAME]
sudo addgroup [USERNAME] ftpuser
sudo usermod -d /var/www/ [USERNAME]
```

# REMOVE USER #
```bash
sudo deluser [USERNAME]
```

# Example config #
```apacheconf
# This file is located at /etc/proftpd/proftpd.conf - ADD IT - DON'T OVERWRITE!!

<Global>
    # Ftp user doesn't need a valid shell
    RequireValidShell off
    # FORWARD THIS PORTS INSIDE THE ROUTER! E.g. 49152 65535 or 60000 60255 (fritz.box)
    PassivePorts 60000 60255
</Global>

# If desired turn off IPv6
UseIPv6 on

# Default directory is ftpusers home
DefaultRoot ~ ftpuser #Locks group 'ftpuser' to its home

# Limit login to the ftpuser group
<Limit LOGIN>
    DenyGroup !ftpuser
</Limit>

ServerIdent on "Welcome on the FTP server."
#Port 4826
#MasqueradeAddress [DOMAIN TO USE FOR PASSIVE PORT IP]

<IfModule mod_tls.c>
    TLSEngine                  on
    TLSLog                     /var/log/proftpd/tls.log
    TLSProtocol                TLSv1.1 TLSv1.2
    TLSCipherSuite             AES128+EECDH:AES128+EDH
    TLSRSACertificateFile      /etc/proftpd/proftpd.cert.pem
    TLSRSACertificateKeyFile   /etc/proftpd/proftpd.key.pem
    TLSVerifyClient            off   
    TLSRenegotiate             none
    # Following due strange behavior at newer Filezilla versions...
    TLSOptions                 NoSessionReuseRequired
    TLSRequired                on
</IfModule>

# The following seems to be buggy so maybe overwirte the config with that...
# Forces all files to XX0
Umask 007 007
```
