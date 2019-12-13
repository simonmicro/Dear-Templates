# Backup #
ADD BACKUP USER TO DATABASE (localhost only) - pwd maybe with 'openssl rand -base64 32'
1. `sudo mysql -u root`
2. `create user 'databaseBackupUser'@'localhost' identified by '[PASSWORD]';`
3. `grant SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER on *.* to 'databaseBackupUser'@'localhost';`
4. `quit;`

BACKUP ALL DATABASES (no space at -p is intentionally)
`mysqldump -u databaseBackupUser -p[PASSWORD] --all-databases --skip-lock-tables > /tmp/databaseExport.sql`

RESTORE ALL DATABASES
`sudo mysql -u root < /tmp/databaseExport.sql`

# Access #
Install `mariadb-server` or `mariadb-client`
Install `phpmyadmin`
\[configure phpmyadmin\]

## Unlock root (works only on localhost) [source](https://kofler.info/root-login-problem-mit-mariadb/) ##
1. `sudo mysql -u root`
2. `select user,host,password,plugin from mysql.user;`
3. `update mysql.user set plugin='' where user='root';`
4. `flush privileges;`
5. `select user,host,password,plugin from mysql.user;`

Change root password:
`SET PASSWORD FOR root@localhost=PASSWORD('password');`

## Create an other (root-)user (works only on localhost) ##
1. `sudo mysql -u root`
2. `CREATE USER username;`
3. `SET PASSWORD FOR username=PASSWORD('password');`
4. (`GRANT ALL PRIVILEGES ON *.* TO 'username'@'%';` **OR (to allow permission modifications too)** `GRANT ALL PRIVILEGES ON *.* TO 'username'@'%' WITH GRANT OPTION;`)
5. (`SHOW GRANTS FOR 'username'@'%';`)
6. `flush privileges;`

## PLEASE NOTE THIS TO ALLOW ACCESS FROM THE INTERNET ##
* `sudo grep -rnw '/etc/mysql' -e 'bind-address' | head -n 1;`
* `sudo nano ...`
* Comment 'bind-address' out
OR ON OLDER MYSQL SERVERS:
* `sudo grep -rnw '/etc/mysql' -e 'skip-networking' | head -n 1;`
* `sudo nano ...`
* Comment 'skip-networking' out

You SHOULD CHANGE the character encoding by `collation-server = utf8mb4_bin` at file `/etc/mysql/mariadb.conf.d/50-server.cnf`

## Note ##
What is debian-sys-maint used for?

By default it is used for telling the server to roll the logs. It needs at least the reload and shutdown privilege.

See the file /etc/logrotate.d/mysql-server

It is used by the /etc/init.d/mysql script to get the status of the server. It is used to gracefully shutdown/reload the server.

Here is the quote from the README.Debian

* MYSQL WON'T START OR STOP?
    > You may never ever delete the special mysql user "debian-sys-maint". This user together with the credentials in /etc/mysql/debian.cnf are used by the init scripts to stop the server as they would require knowledge of the mysql root users password else.
