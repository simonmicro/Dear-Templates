---
summary: Some common templates for avahi services
---

# Note #
This all requires the `avahi-daemon` package.
Also make sure the new service file is readible by the avahi daemon - a `chmod 664` is enough, but is in most cases required!

## FTP ##
Located at `/etc/avahi/services/ftp.service`
```
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
   <name replace-wildcards="yes">%h</name>
   <service>
       <type>_ftp._tcp</type>
       <port>21</port>
   </service>
</service-group>
```

## HTTP ##
Located at `/etc/avahi/services/http.service`
```
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
   <name replace-wildcards="yes">%h</name>
   <service>
       <type>_http._tcp</type>
       <port>80</port>
   </service>
</service-group>
```

## HTTPS ##
Located at `/etc/avahi/services/https.service`
```
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
   <name replace-wildcards="yes">%h</name>
   <service>
       <type>_https._tcp</type>
       <port>443</port>
   </service>
</service-group>
```

## Samba ##
Located at `/etc/avahi/services/samba.service`
```
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
   <name replace-wildcards="yes">%h</name>
   <service>
       <type>_smb._tcp</type>
       <port>445</port>
   </service>
</service-group>
```

## SSH ##
Located at `/etc/avahi/services/ssh.service`
```
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
   <name replace-wildcards="yes">%h</name>
   <service>
       <type>_sftp-ssh._tcp</type>
       <port>22</port>
   </service>
</service-group>
```
