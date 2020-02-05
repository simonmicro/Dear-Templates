Take a look into the minidlna.conf file (you'll be able to pull the status of the minidlna server at the port 8200)!
Maybe you should add a cronjob to rescan the network attached folders every midnight by restarting the server...
```
0 4 * * * systemctl restart minidlna
```
