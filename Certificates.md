---
title: Certificates
summary: Fast script to generate a self-signed certificate for apache
type: blog
banner: "/img/dear-templates/default.jpg"
---

```
echo "Step 1: Generate a Private Key"
openssl genrsa -des3 -out server.key

echo "Step 2: Generate a CSR (Certificate Signing Request)"
openssl req -new -key server.key -out server.csr

echo "Step 3: Remove Passphrase from Key"
cp server.key server.key.org
openssl rsa -in server.key.org -out server.key

echo "Step 4: Generating a Self-Signed Certificate"
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

echo "Step 5: Installing the Private Key and Certificate (DO IT YOURSELF)"
rm server.csr
rm server.key.org
```
