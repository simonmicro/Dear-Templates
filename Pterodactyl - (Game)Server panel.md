---
summary: Manage & create all your (game)servers and services using a dead-simple web ui
---

# Install the panel
```bash
# As first we need PHP 8.0+ on Debian ([reference](https://computingforgeeks.com/how-to-install-latest-php-on-debian/))...
sudo apt install apache2 php8.0 redis-server

# Install needed php modules
sudo apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} tar unzip git redis-server
sudo a2enmod php8.0

# Install composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```

Now modify `000-default.conf` to point to the correct (Pterodactyl) directory (e.g. `/var/www/pterodactyl/public`)
Also make sure to insert this:
```apache
# To allow .htaccess inside the pages root dir
    <Directory /var/www/pterodactyl>
        AllowOverride All
    </Directory>
```

And allow the webserver to access it:
```bash
sudo chown www-data -Rv /var/www/pterodactyl
sudo -u www-data bash
```

Now get the files according to [this](https://pterodactyl.io/panel/1.0/getting_started.html#download-files)...

```bash
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force

php artisan p:environment:setup
```

-> insert this:
```
pterodactyl@example.com
https://pterodactyl.example.com
Europe/Berlin
redis
redis
redis
yes
[]
[]
[]
```

Setup the db:
```bash
php artisan p:environment:database
```

-> insert this:
```
db.example.com
[]
[DB_USER]
[]
[DB_PASSWORD]
```

Setup the mail:
```bash
php artisan p:environment:mail
```

-> insert this:
```
smtp
mail.example.com
587
pterodactyl@example.com
[MAIL_PASSWORD]
pterodactyl@example.com
[]
tls
```

```bash
php artisan migrate --seed --force
php artisan p:user:make
```

-> insert this:
```
yes
[ADMIN_EMAIL]
root
Super
Admin
[ADMIN_PASSWORD]
```

And make sure the files permissions are correct (again):
```bash
sudo chown www-data -Rv /var/www/pterodactyl
```

Also add on the webserver the cronjob...
```bash
sudo -u www-data crontab -e
```

-> append this:
```
* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1
```

...AND the queue worker (which sends out the emails) - see [here](https://pterodactyl.io/panel/1.0/getting_started.html#create-queue-worker).
Now enable all the services:
```bash
sudo systemctl enable --now redis-server
sudo systemctl enable --now pteroq.service
```

# Install any reverse proxy
On your (existing) apache reverse proxy vm run:
```bash
sudo a2enmod rewrite
```

_Now setup your reverse proxy as always..._ Here are some notes regarding this (for Apache):
* Must enable `ProxyPreserveHost`
* Run
    ```bash
    sudo a2enmod remoteip
    ```
* Add to the VirtualHost
    ```apache
    RemoteIPHeader X-Client-IP
    RemoteIPHeader X-Forwarded-For
    RequestHeader set X-Forwarded-Proto https
    ```

Now add to the Pterodactyl config (the `.env` file):
```ini
TRUSTED_PROXIES=[YOUR_PROXY_IP]
```

# Setup your first wings (panel)
* Add a new location
* Add a new node "[FQDN_OF_THE_NODE]", fqdn=[FQDN_OF_THE_NODE], daemon-port=[RANDOM_PORT_NUMBER], stfp-port=[RANDOM_PORT_NUMBER], ...
* These random ports MUST BE publicy exposed!
* Create new ip allocations - e.g.:
    * 0.0.0.0, wildcard, 8733
    * [INTERNAL_VM_IP], internal, 2341 -> Internal tests
    * 127.0.0.1, localhost, 20392 -> for Bungeecord
* I really recommend creating a trunk allocation with ~256 ports.

# Setup your first wings (vm)
Mainly use [this](https://pterodactyl.io/wings/1.0/installing.html):
```bash
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod u+x /usr/local/bin/wings
```
Now install the config from the panel & start manually with `--debug`.
Also mount some letsencrypt certs into the vm to `/etc/letsencrypt`, so wings can use them (just obtain them on your reverse proxy using a redirect)...
Final notes:
* When getting CORS errors, make sure (e.g. via `curl`) you can reach wings using the FQDN - maybe the config is messed up and uses the wrong ports...
* When getting DNS erros on server start: Check the wings config for correct DNS servers - maybe even correct them!
* I mounted via NFS all server data to `/var/lib/pterodactyl`

# MINIO for server backups
Just slap a new `docker-compose.yml` together with:
```
version: '3'
services:
    minio-pterodactyl:
        image: minio/minio
        restart: always
        volumes:
            - [PATH_TO_ALL_YOUR_BACKUP_DATA]:/data
        environment:
            MINIO_REGION_NAME: 'default'
            MINIO_ROOT_USER: 'root'
            MINIO_ROOT_PASSWORD: '[STRONG_MASTER_PASSWORD]'
        ports:
            - [RANDOM_PORT]:9000
        command: server /data
```
Now login to the ui (which runs on the same port) and create a new bucket called `pterodactyl`.

Finally extend the `.env` config once again:
```ini
# Sets your panel to use s3 for backups
APP_BACKUP_DRIVER=s3

# Info to actually use s3
AWS_DEFAULT_REGION=default
AWS_ACCESS_KEY_ID=root
AWS_SECRET_ACCESS_KEY=[STRONG_MASTER_PASSWORD]
AWS_BACKUPS_BUCKET=pterodactyl
AWS_ENDPOINT=http://[MINIO_HOST_IP]:[MINIO_PORT]
```
And here is a working demo for RUST: https://wasabi-support.zendesk.com/hc/en-us/articles/360058097232-How-do-I-use-Pterodactyl-with-Wasabi-

Now navigate to the `Build configuration` of your server(s) and enter an allowed backup count to enable this feature.

# Notes
* I cloned the wings vm for one instance without any NFS integration (as needed for e.g. Starbound - as it locks the world, which is unsupported by NFS)
