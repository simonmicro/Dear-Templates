# Install repo #
- Auto restart
- Runs on port 5425
- Mounts /etc/letsencrypt/live/domain.example.com to repositories /certs

## Prepare certificates ##
### Initially create the certificate ###
certbot certonly --standalone --preferred-challenges http --non-interactive  --staple-ocsp --agree-tos -m webmaster@example.com -d example.com

### Add crontab for renewing ###
cat <<EOF > /etc/cron.d/letencrypt
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
30 2 * * 1 root /usr/bin/certbot renew >> /var/log/letsencrypt-renew.log && cd /etc/letsencrypt/live/example.com && cp privkey.pem domain.key && cat cert.pem chain.pem > domain.crt && chmod 777 domain.*
EOF

## Prepare the storage ##
`mkdir -p /mnt/docker-registry`

## Prepare authentication ##
`docker run --entrypoint htpasswd registry:latest -Bbn [USER] [PASSWORD]` - add it to: /mnt/docker-registry/passfile

## Start the registry ##
```
docker run -d \
  -p 5425:5000 \
  --restart=always \
  --name registry \
  -v /mnt/docker-registry:/var/lib/registry \
  -v /etc/letsencrypt/live/domain.example.com:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -e REGISTRY_AUTH=htpasswd \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/var/lib/registry/passfile \
  registry:latest
```

## Test it! ##
`curl https://testuser:testpass@[REG_HOST]:[REG_PORT]/v2/_catalog`

# Push / Pull image #
Push:
1. `docker tag [MYIMAGE] [REG_HOST]:[REG_PORT]/[NEW_NAME]`
2. `docker push [REG_HOST]:[REG_PORT]/[NEW_NAME]`

Pull:
1. `docker pull [REG_HOST]:[REG_PORT]/[NEW_NAME]`
2. `docker tag [REG_HOST]:[REG_PORT]/[NEW_NAME] [MYIMAGE]`

# Add repo creds to client #
`docker login [REG_HOST]:[REG_PORT]`

# Auto cleanup: Crontab! #
-> Add on weekly basis `docker system prune -f`
