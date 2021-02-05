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
openssl req -new -days 365 -x509 -key radius.key -out radius.crt
```

## Convert your CRT to a PEM
```bash
openssl x509 -in radius.crt -out radius.pem -outform PEM
openssl x509 -in ca.crt -out ca.pem -outform PEM
```

## Push it to the gateway!
-> Upload new certs+key to the /tmp dir (`radius.key` -> `server.key` and also `radius.pem` -> `server.pem`). Then run
```bash
sudo bash
chmod -v 770 /tmp/ca.pem
chmod -v 770 /tmp/server.key
chmod -v 770 /tmp/server.pem
chown -v root: /tmp/ca.pem
chown -v root: /tmp/server.key
chown -v root: /tmp/server.pem
cp -v /tmp/ca.pem /etc/freeradius/certs/
cp -v /tmp/server.key /etc/freeradius/certs/
cp -v /tmp/server.pem /etc/freeradius/certs/
```

## Finalize!
Reboot the Gateway to restart FreeRadius & wipe the tmp dir, which holds the sensitive information!
```bash
reboot
```

# Trust ROOT-CA on Ubuntu
```bash
sudo mkdir /usr/share/ca-certificates/extra
sudo cp ca.crt /usr/share/ca-certificates/extra/ca.crt
sudo update-ca-certificates
```

[Further reference](https://gist.github.com/Soarez/9688998)
