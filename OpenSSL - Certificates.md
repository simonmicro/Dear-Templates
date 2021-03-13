---
summary: Fast script to generate a self-signed certificate for any purpose
---

# Create your own CA
```bash
openssl genrsa -out ca.key 2048 # Generate new private key
openssl req -new -days 3650 -x509 -key ca.key -out ca.crt -subj '/CN=root-ca'
```

## ...and sign a certificate
```bash
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj '/CN=server'
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
```

# Revoke any certificate of your CA
Create a new file at `/tmp/ca_crl.cnf`:
```ini
[ca]
default_ca = my_ca

[my_ca]
database = ca.db
certificate = ca.crt
private_key = ca.key
default_md = default
default_crl_days = 32
```
And create the empty database:
```bash
touch ca.db
```

Now you can revoke any previously signed certificate just by using:
```bash
openssl ca -revoke [CLIENT_CERTIFICATE_TO_REVOKE].crt -config /tmp/ca_crl.cnf
```
