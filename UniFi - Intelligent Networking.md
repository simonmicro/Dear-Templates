---
summary: How to be your own CA and install your own certificates on the UniFi devices.
---

# Create your new CA
```bash
openssl genrsa -out ca.key 2048 # Generate new private key
openssl req -new -days 3650 -x509 -key ca.key -out ca.crt # Generate new public certificate
```
When anyone choose to trust you, he has to import the public CA certificate (you should host it publicly accessible) - it is valid for 10 years, so no stress here!

# Install on UniFi Controller

## Request the CSR (on controller)
```bash
java -jar lib/ace.jar new_cert <hostname> <company> <city> <state> <country>
```

## Sign the CSR
```bash
openssl x509 -req -in unifi_certificate.csr.pem -CA ca.crt -CAkey ca.key -CAcreateserial -out controller.crt
```
**MAKE SURE TO REMOVE ALL LINE BREAKS ON THE CERTIFICATES OF THE CA/CONTROLLER NOW!** Otherwise the import will just not work, because... Idk.

## Reimport new CRT (on controller)
```bash
java -jar lib/ace.jar import_cert data/controller.crt data/ca.crt
```

# Install on UniFi Gateway: FreeRadius
...needed for WPA2-Enterprise functionality!

## Generate new private key
```bash
openssl genrsa -out radius.key 2048
```

## Generate a new CRT
```bash
openssl req -new -key radius.key -out radius.csr
openssl x509 -req -days 365 -in radius.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out radius.crt
```

## Convert your CRT to a PEM
```bash
openssl x509 -in radius.crt -out radius.pem -outform PEM
openssl x509 -in ca.crt -out ca.pem -outform PEM
```

## Push it to the gateway!
-> Upload new certs+key to the `/tmp` dir. Then run
```bash
sudo bash
mv /tmp/radius.key /tmp/server.key
mv /tmp/radius.pem /tmp/server.pem
chmod -v 770 /tmp/ca.pem
chmod -v 770 /tmp/server.key
chmod -v 770 /tmp/server.pem
chown -v freerad: /tmp/ca.pem
chown -v freerad: /tmp/server.key
chown -v freerad: /tmp/server.pem
mv /tmp/ca.pem /etc/freeradius/certs/
mv /tmp/server.key /etc/freeradius/certs/
mv /tmp/server.pem /etc/freeradius/certs/
```

## Finalize!
Restart FreeRadius to apply the new certificate:
```bash
service freeradius restart
```

# Trust ROOT-CA on Ubuntu
```bash
sudo mkdir /usr/share/ca-certificates/extra
sudo cp ca.crt /usr/share/ca-certificates/extra/ca.crt
sudo update-ca-certificates
```

[Further reference](https://gist.github.com/Soarez/9688998)
