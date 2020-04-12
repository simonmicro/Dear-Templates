---
title: Apache
summary: Templates for sites and hardening
type: blog
slug: .
banner: "/img/placeholder.png"
---

# Templates #
The following are mostly located under `/etc/apache/sites-available` - just copy-paste and enjoy!

## Virtual Host ##
```
#
# Replace example.com with your domain
# 
<VirtualHost *:80>
# Server Name (a,aaaa,cname)
    ServerName example.com
# E.g. mail for 500 error       
    ServerAdmin webmaster@example.com
# NO HTTP, forward to HTTPS             
    Redirect permanent / https://example.com/
# Log stuff
    ErrorLog /var/log/apache2/example.com-http-error.log
    CustomLog /var/log/apache2/example.com-http-access.log common
</VirtualHost>

<VirtualHost *:443>
# Server Name (a,aaaa,cname)
    ServerName example.com
# E.g. mail for 500 error       
    ServerAdmin webmaster@example.com
# Where PHP and HTML is located (HTTPS)
    DocumentRoot /var/www/example.com
# ...or proxy everything from...
#    ProxyPass / http://localhost:19999/
#    ProxyPassReverse / http://localhost:19999/
# DON'T inform the proxy target, that an other client has requested the site instead of this server (don't set X-Forward...)
#    ProxyPreserveHost on
# Use SSL + stuff
    SSLEngine on
# ...allow SSL on the proxy...
    SSLProxyEngine on
# ...to enforce the validity of the proxied server target...
    SSLProxyCheckPeerCN on
    SSLProxyCheckPeerExpire on
# The following in case no letsencrypt cert is there
    SSLCertificateFile /etc/ssl/certs/apache.crt
    SSLCertificateKeyFile /etc/ssl/private/apache.key
# ...and the lesencrypt version (check this with the certbot output)
#    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
#    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem

# Log stuff
    ErrorLog /var/log/apache2/example.com-https-error.log
    CustomLog /var/log/apache2/example.com-https-access.log common

# To allow .htaccess in DocumentRoot
#    <Directory /var/www/example.com>
#        AllowOverride All
#    </Directory>

# Block access to any .git folder...
#    <Directorymatch "^/.*/\.git/">
#        Order deny,allow
#        Deny from all
#    </Directorymatch>

# To force htpasswd authentication
# The htpasswd file is created with "sudo htpasswd [-c (ONLY FOR FIRST USER)] /etc/htpasswd [INITIAL_USER]" --- MAKE SURE TO CHOWN THE FILE CORRECTLY!
# A user is added with "sudo htpasswd /etc/htpasswd [USER]"
# A user is deleted with "sudo htpasswd -D /etc/htpasswd [USER]"
#    <Location />
#        AuthType Basic
#        AuthName "Authentication Required"
#        AuthUserFile "/etc/htpasswd"
#        Require valid-user
#
#        Order allow,deny
#        Allow from all
#    </Location>

# To force LDAP authentication
#    <Location />
#        AuthType Basic
#        AuthBasicProvider ldap
#        AuthName "Authentication Required"
#        # Connect to the LDAP server anonymously...
#        AuthLDAPURL ldap://localhost:389/OU=[OU of users],DC=example,DC=com
#        # LDAP login requirements (s. documantation)...
#        AuthLDAPGroupAttribute memberUid
#        AuthLDAPGroupAttributeIsDN off
#        Require ldap-group CN=[required group],OU=[OU of groups],DC=example,DC=com
#    </Location>

# Following needed if lets-encrypt with active auth is wanted...
#    <Location /.well-known>
#        Require all granted
#    </Location>
</VirtualHost>
```

## Default Host ##
```
###THIS NEEDS TO BE NAMED AS 000-default.conf###

<VirtualHost *:80>
    #E.g. mail for 500 error	
        ServerAdmin webmaster@example.com
    #Where default site is located (HTTP)
        DocumentRoot /var/www/default
    #Log stuff
        ErrorLog /var/log/apache2/default-http-error.log
        CustomLog /var/log/apache2/default-http-access.log common
</VirtualHost>
<VirtualHost *:443>
    #E.g. mail for 500 error	
        ServerAdmin webmaster@example.com
    #Where default site is located (HTTPS)
        DocumentRoot /var/www/default
    #Use SSL + stuff
        SSLEngine on									
        SSLCertificateFile /etc/ssl/certs/apache.crt
        SSLCertificateKeyFile /etc/ssl/private/apache.key
    #Log stuff
        ErrorLog /var/log/apache2/default-https-error.log
        CustomLog /var/log/apache2/default-https-access.log common
</VirtualHost>
```

## Simple .htaccess ##
```
# No file lists!
Options -Indexes

# Block any access to here (useful for e.g. lib/ folders)
#deny from all

<ifModule mod_rewrite.c>
    # Force HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</ifModule>
```

# Harden Apache #

### Hide Apache Version and OS Identity ###
Append to `/etc/apache2/apache2.conf`
```
ServerSignature Off
ServerTokens Prod
```
