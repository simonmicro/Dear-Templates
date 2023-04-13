---
summary: Own registry, container auto updates and maintenance stuff!
---

# Setup a registry #
- Auto restart
- Runs on port 5425
- Mounts /etc/letsencrypt/live/domain.example.com to repositories /certs

## Prepare certificates ##
### Initially create the certificate ###
```bash
certbot certonly --standalone --preferred-challenges http --non-interactive  --staple-ocsp --agree-tos -m webmaster@example.com -d example.com
```

### Add crontab for renewing ###
Add this to `/etc/cron.d/letencrypt`
```
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
30 2 * * 1 root /usr/bin/certbot renew >> /var/log/letsencrypt-renew.log && cd /etc/letsencrypt/live/example.com && cp privkey.pem domain.key && cat cert.pem chain.pem > domain.crt && chmod 777 domain.*
```

## Prepare the storage ##
```bash
mkdir -p /mnt/docker-registry
```

## Prepare authentication ##
```bash
docker run --entrypoint htpasswd registry:latest -Bbn [USER] [PASSWORD]
```
-> add it to: `/mnt/docker-registry/passfile`

## Start the registry ##
```bash
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

# Automatic docker image updates? Watchtower! #
Watchtower is an automatic updater, which stops, repulls, and restarts all specified images...

## Add creds for private registry ##
```json
{
    "auths": {
        "<REGISTRY_NAME>": {
            "auth": "[USERNAME_PASSWORD_BASE64]"
        }
    }
}
```
Replace the `[USERNAME_PASSWORD_BASE64]` with the output of `echo -n '[REG_USERNAME]:[REG_PASSWORD]' | base64`.
For the creds you must add a new user to gitlab wich can see the docker images from the repo...
Save the new file to a secure location on the vm and write down the absolute path.

# Start watchtower updater! #
```bash
docker run -d \
    --name watchtower \
    -v [ABSOLUTE_PATH_TO_PRIVATE_REGISTRY_CREDENTIALS]:/config.json \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e WATCHTOWER_NOTIFICATIONS=email \
    -e WATCHTOWER_NOTIFICATION_EMAIL_FROM=[FROM_EMAIL] \
    -e WATCHTOWER_NOTIFICATION_EMAIL_TO=[TO_EMAIL] \
    -e WATCHTOWER_NOTIFICATION_EMAIL_SERVER=[EMAIL_SERVER] \
    -e WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587 \
    -e WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER=[EMAIL_USER_SERVER] \
    -e WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD=[EMAIL_PASS_SERVER] \
    -e WATCHTOWER_NOTIFICATION_EMAIL_DELAY=2 \
    -e WATCHTOWER_CLEANUP: 'true' \
    -e WATCHTOWER_SCHEDULE: '0 0 4 * * *' \
    -e WATCHTOWER_ROLLING_RESTART: 'true' \
    -e WATCHTOWER_TIMEOUT: '360s' \
    containrrr/watchtower
```
**Make sure to insert the path to the private registry file!**
* The credentials part can be omitted, if not needed...
* The email part can be omitted, if not needed...
* The watchtower will update all images every day at 4 o'clock
* It will delete the now unused image tags / versions
* It will wait 6 minutes until a forceful update to stop the container (using docker stop)

# Automatic pruning #
Sometimes some old cache containers or images could be left over - as they sometimes get automatically created (depending on your setup) they will use more and more disk space.
To cirumvent that we can create a new SystemD timer (so it only runs, when docker runs) and set it up to prune any old remains. For that create as first a new timer for systemd:

Create `/etc/systemd/system/docker-cleaner.timer`:
```systemd
[Unit]
Description=Prune docker images, volumes, containers & networks
Requires=docker-cleaner.service

[Timer]
Unit=docker-cleaner.service
OnCalendar=*-*-* 00:00:00
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
```

And the service file `/etc/systemd/system/docker-cleaner.service`:
```systemd
[Unit]
Description=Prune docker images, volumes, containers & networks
Wants=docker-cleaner.timer

[Service]
Type=oneshot
# MAKE SURE YOU DO NOT USE DOCKERS INTERNAL VOLUMES, as they will be deleted!
ExecStart=docker system prune -a -f --volumes

[Install]
WantedBy=multi-user.target
```

Now you should be ready to go! Activate the service and start it by hand for once (just to make sure it works):
```bash
sudo systemctl enable docker-cleaner.timer
sudo systemctl start docker-cleaner.service
```
