---
summary: Templates for vitual hosts (https with LetsEncrypt, proxies, authentication and more) and hardening
---

# Templates #
The following are mostly located under `/etc/apache/sites-available` - just copy-paste and enjoy!

## Virtual Host ##
```apacheconf
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
    ErrorLog /var/log/apache2/example.com-error.log
    CustomLog /var/log/apache2/example.com-access.log combined
</VirtualHost>

<VirtualHost *:443>
# Server Name (a,aaaa,cname)
    ServerName example.com
# E.g. mail for 500 error       
    ServerAdmin webmaster@example.com
# Where PHP and HTML is located (HTTPS)
    DocumentRoot /var/www/example.com
# ...or proxy everything from (the following is for any custom error pages; make sure to also enable the DocumentRoot directive)...
#    ProxyPass /_error !
#    ProxyErrorOverride On
#    ErrorDocument 404 /_error/404.html
#    ErrorDocument 500 /_error/500.html
#    ErrorDocument 502 /_error/502.html
#    ErrorDocument 503 /_error/503.html
#    ErrorDocument 504 /_error/504.html
# ...make also sure to support websockets...
#    ProxyPass /socket ws://localhost:31363/socket
# ...with some software you'll may need a regex based pass:
#    ProxyPass ^/api/(.*)/ws$ ws://localhost:31363/api/$1/ws
#    ProxyPassReverse /socket ws://localhost:31363/socket
# ...and now the proxy target from (note the order of these proxy statements - the first matches will be choosen!)...
#    ProxyPass / http://localhost:31363/
#    ProxyPassReverse / http://localhost:31363/
# DON'T inform the proxy target, that an other client has requested the site instead of this server (don't set X-Forward...)
#    ProxyPreserveHost on
# Use SSL + stuff
    SSLEngine on
# ...allow SSL on the proxy...
#    SSLProxyEngine on
# ...to enforce the validity of the proxied server target...
#    SSLProxyCheckPeerCN on
#    SSLProxyCheckPeerExpire on
# The following in case no letsencrypt cert is there
    SSLCertificateFile /etc/ssl/certs/apache.crt
    SSLCertificateKeyFile /etc/ssl/private/apache.key
# ...and the lesencrypt version (check this with the certbot output)
#    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
#    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem

# Log stuff
    ErrorLog /var/log/apache2/example.com-error.log
    CustomLog /var/log/apache2/example.com-access.log combined

# To allow .htaccess inside the pages root dir
#    <Directory /var/www/example.com>
#        AllowOverride All
#    </Directory>

# To force htpasswd authentication
# The htpasswd file is created with "sudo htpasswd [-c (ONLY FOR FIRST USER)] /etc/htpasswd [INITIAL_USER]" --- MAKE SURE TO CHOWN THE FILE CORRECTLY!
# A user is added with "sudo htpasswd /etc/htpasswd [USER]"
# A user is deleted with "sudo htpasswd -D /etc/htpasswd [USER]"
#    <Location />
#        AuthType Basic
#        AuthName "Authentication Required"
#        AuthUserFile "/etc/htpasswd"
#        Require valid-user
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

# Following is needed if lets-encrypt with active auth is wanted...
#    <Location /.well-known>
#        Require all granted
#    </Location>
</VirtualHost>
```

## Default Host ##
### THIS FILE NEEDS TO BE NAMED AS 000-default.conf ###
It also expects to have a `404.html` and a `50x.html` inside the `_error` directoy, you could orient your page on [my own](https://gitlab.simonmicro.de/simonmicro/apache-defaults) ones.
```apacheconf
<VirtualHost *:80>
    #Where default site is located (HTTP)
        DocumentRoot /var/www/default
        ErrorDocument 404 /_error/404.html
        ErrorDocument 500 /_error/500.html
        ErrorDocument 502 /_error/502.html
        ErrorDocument 503 /_error/503.html
        ErrorDocument 504 /_error/504.html
    #Log stuff
        ErrorLog /var/log/apache2/default-error.log
        CustomLog /var/log/apache2/default-access.log combined
</VirtualHost>
<VirtualHost *:443>
    #Where default site is located (HTTPS)
        DocumentRoot /var/www/default
        ErrorDocument 404 /_error/404.html
        ErrorDocument 500 /_error/500.html
        ErrorDocument 502 /_error/502.html
        ErrorDocument 503 /_error/503.html
        ErrorDocument 504 /_error/504.html
    #Use SSL + stuff
        SSLEngine on									
        SSLCertificateFile /etc/ssl/certs/apache.crt
        SSLCertificateKeyFile /etc/ssl/private/apache.key
    #Log stuff
        ErrorLog /var/log/apache2/default-error.log
        CustomLog /var/log/apache2/default-access.log combined
</VirtualHost>

# Block access to any .git folder - for more information why and how see...
# * https://www.heise.de/ct/artikel/Massive-Sicherheitsprobleme-durch-offene-Git-Repositorys-4795181.html
# * https://www.tagesschau.de/investigativ/ndr/it-sicherheit-quellcodes-101.html
# * https://www.zeit.de/2020/28/datensicherheit-computer-server-deutschland-gefahr
<Directorymatch "^/.*/\.git/">
# OR more aggressive with...
# <Directorymatch "^/.*/\.git.*">
    Require all denied
</Directorymatch>

# And some good practices...
<IfModule headers_module>
    header set X-Clacks-Overhead "GNU Terry Pratchett"
    header set X-Cat: "😸"
</IfModule>
```

## Simple .htaccess ##
```apacheconf
# No file lists!
Options -Indexes

# Block any access to here (useful for e.g. lib/ folders)
#Require all denied

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
```apacheconf
ServerSignature Off
ServerTokens Prod
```
