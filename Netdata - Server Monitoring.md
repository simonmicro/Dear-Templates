---
title: Netdata - Server Monitoring
summary: Setup, replication and some config hints
type: blog
banner: "/img/dear-templates/default.jpg"
---

# Setup #
1. Install with `sudo apt install netdata` (preferred) or `bash <(curl -Ss https://my-netdata.io/kickstart.sh)` or `bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)`
2. **Restrict to localhost only (already done for the debian package)** by appending (`sudo /etc/netdata/edit-config netdata.conf`):
    ```
    [web]
        bind to = *:19999
        allow connections from = localhost 42.12.322.424
    ```
    _This allows other ips to be whitelisted: E.g. an apache proxied webinterface would require localhost - any other ip must be allowed!_
3. Restart netdata `sudo systemctl restart netdata`
4. NICE2KNOW Check the generated config out at http://localhost:19999/netdata.conf

## Extend the history ##
By using (`sudo /etc/netdata/edit-config netdata.conf`):
    *
        ```
        [global]
            history = SECONDS
        ```
        > For every hour of data, Netdata needs about 25MB of RAM. If you can dedicate about 100MB of RAM to Netdata, you should set its database size to 4 hours.

    *
        ```
        [global]
            memory mode = dbengine
            page cache size = 32
            dbengine disk space = 256
        ```
        > This holds 32 MB of data in RAM and dumps (compresses) them to disk until 256 MB are stored. 
        
## Setup a slave / master relationship ##
This configures a netdata instance to only collect and send the metrics to the master (the slave cant generate alarms anymore). Both must share the same API KEY (obtained by `uuidgen`)! The master then can decide to store the data e.g. to the dbengine or keep them in ram...
Note:

* `enabled` toggles if the data should be send (on slave toggles the feature, on master it toggles the proxy mode)
* The api key can be shared from multiple hosts
* The master can select other [memory modes](https://docs.netdata.cloud/streaming/) too - every unset option will be inherited from the default* ones
* `allow from` are [simple patterns](https://docs.netdata.cloud/libnetdata/simple_pattern/) -> `10.0.0.*` or `!192.168.0.1` or `*`...

### Slave ###
3. Edit the global config: `sudo /etc/netdata/edit-config netdata.conf`
4. Disable own storage and webinterface (= slave mode):
    ```
    [global]
        memory mode = none
    [web]
        mode = none
    ```
3. Edit the config: `sudo /etc/netdata/edit-config stream.conf`
4. Now add the master (append ':SSL' to the address for https (respect the port!)):
    ```
    [stream]
        enabled = yes
        destination = [TARGET_ADDR]:[TARGET_WEB_PORT]
        api key = xxxxxxxx-xxxx-xxxxx-xxxx-xxxxxxxxxxxx
    ```

### Master ###
1. Edit the config: `sudo /etc/netdata/edit-config stream.conf`
2. Now add the slave:
    ```
    [xxxxxxxx-xxxx-xxxxx-xxxx-xxxxxxxxxxxx]
        enabled = yes
        default memory mode = dbengine
        health enabled by default = auto
        allow from = 10.0.0.*
    ```
    
### Add this to the crontab... ###
You should add the following to the crontab of root. This makes sure that netdata "starts" after e.g. the local loopback interface is up, so it binds also to that address (_otherwise the vms could get a connection refused after bootup_).
```
@reboot sleep 60 && systemctl restart netdata
```

# Add teleram bot notifications #
1. Edit the config with `sudo /etc/netdata/edit-config health_alarm_notify.conf` and modify it so it contains:
    ```
    SEND_TELEGRAM="YES"
    TELEGRAM_BOT_TOKEN="[BOT_API_TOKEN]"
    DEFAULT_RECIPIENT_TELEGRAM="[TARGET_CHAT_ID]"
    ```
2. Done - test it ([see here at the end](https://docs.netdata.cloud/health/notifications/email/))

# How to mute a specific alarm #
One or more alarms are useless and can be ignored? Check out the source row at the dashboard (-> e.g. `sudo /etc/netdata/edit-config health.d/...`). Go there and change the recipient from `to: [someone]` to `to: silent`. Or disable it by comment it with # out!

~ Finally: Quiet nights! ~

# How to prevent package drop warnings without muting the alarm #
1. Apply `sudo sysctl -w net.core.netdev_budget_usecs=6400 && sudo sysctl -w net.core.netdev_budget=600` as temporary fix. The alarm should now fade.
2. If that was successful: Apply them permanent in /etc/sysctl.conf by adding:
    ```
    net.core.netdev_budget_usecs=6400
    net.core.netdev_budget=600
    ```

# Usage #
1. Establish a tunnel to the server: `ssh -N -L [LOCAL_PORT]:127.0.0.1:19999 [TARGET_ADDR]`
2. Open your browser: `firefox localhost:[LOCAL_PORT]`

## Example script to connect to multiple nodes ##
```
echo "*****Connecting to [SERVER1_NAME]..."
ssh -f -N -L 20000:127.0.0.1:19999 [SERVER1_PORT]
echo "*****Connecting to [SERVER2_NAME]..."
ssh -f -N -L 20001:127.0.0.1:19999 [SERVER2_PORT]
echo "*****Connecting to [SERVER3_NAME]..."
ssh -f -N -L 20002:127.0.0.1:19999 [SERVER3_PORT]
echo "*****Connecting to [SERVER4_NAME]..."
ssh -f -N -L 20003:127.0.0.1:19999 [SERVER4_PORT]

address=http://localhost:20000/
echo "*****Starting firefox for $address..."
echo "You should have added all servers as node already (simply sign in on them) to see them by clocking on nodes!"
firefox $address &
sleep 5
```

## Example script to connect to disconnect from multiple nodes ##
```
echo "*****Killing all connections..."
pkill -e -f "ssh -f -N -L 200"

echo "*****Connections closed."
sleep 5
```

# Nett2Know #
If you get much dbengine fs errors and can't add any more working instances to the netdata streaming config (the access.log is filled with `CANNOT ACQUIRE HOST`) you should [increase the file descriptor limit](https://github.com/netdata/netdata/blob/master/database/engine/README.md).

# Update (non-debian package only) #
`sudo chmod +x /opt/netdata/usr/libexec/netdata/netdata-updater.sh && sudo /opt/netdata/usr/libexec/netdata/netdata-updater.sh`

# Uninstall (non-debian package only) #
`sudo chmod +x /opt/netdata/usr/libexec/netdata/netdata-uninstaller.sh && sudo /opt/netdata/usr/libexec/netdata/netdata-uninstaller.sh`
