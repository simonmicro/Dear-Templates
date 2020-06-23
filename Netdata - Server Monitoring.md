---
summary: Setup, replication, notifications and some further config hints
---

# Setup #
1. Install with `bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)` or (on e.g. a Raspberry Pi) `bash <(curl -Ss https://my-netdata.io/kickstart.sh)`
2. **Restrict to localhost only (already done for the debian package)** by appending (`sudo /opt/netdata/etc/netdata/edit-config netdata.conf`):
    ```ini
    [web]
        bind to = *:19999
        allow connections from = localhost 42.12.322.424
    ```
    _This allows other ips to be whitelisted: E.g. an apache proxied webinterface would require localhost - any other ip must be allowed!_
3. Restart netdata `sudo systemctl restart netdata`
4. NICE2KNOW Check the generated config out at http://localhost:19999/netdata.conf

## Enable autostart (if disabled) ##
To allow autostarting of the `netdata` service you have to unmask the systemd unit with `sudo systemctl unmask netdata` and `sudo systemctl enable netdata`...

## Claim a node ##
Just use the command from the cloud - but make sure to add `/opt/netdata/bin/` before the `netdata-claim.sh` shell.

## Extend the history ##
By using (`sudo /opt/netdata/etc/netdata/edit-config netdata.conf`) - `dbengine` is the default:
* ```ini
  [global]
      memory mode = dbengine
      page cache size = 32
      dbengine disk space = 330
  ```
  > This holds 32 MB of data in RAM and dumps (compresses) them to disk until 330 MB are stored. This would be enough to store the history of one day - [according to this](https://learn.netdata.cloud/docs/agent/database/calculator).
* ```ini
  [global]
      history = SECONDS
  ```
  > For every hour of data, Netdata needs about 25MB of RAM. If you can dedicate about 100MB of RAM to Netdata, you should set its database size to 4 hours.
        
## Setup a slave / master relationship ##
This configures a netdata instance to only collect and send the metrics to the master (the slave cant generate alarms anymore). Both must share the same API KEY (obtained by `uuidgen`)! The master then can decide to store the data e.g. to the dbengine or keep them in ram...
Note:

* `enabled` toggles if the data should be send (on slave toggles the feature, on master it toggles the proxy mode)
* The api key can be shared from multiple hosts
* The master can select other [memory modes](https://docs.netdata.cloud/streaming/) too - every unset option will be inherited from the default* ones
* `allow from` are [simple patterns](https://docs.netdata.cloud/libnetdata/simple_pattern/) -> `10.0.0.*` or `!192.168.0.1` or `*`...

### Slave ###
3. Edit the global config: `sudo /opt/netdata/etc/netdata/edit-config netdata.conf`
4. Disable own storage and webinterface (= slave mode):
    ```ini
    [global]
        memory mode = none
    [web]
        mode = none
    ```
3. Edit the config: `sudo /opt/netdata/etc/netdata/edit-config stream.conf`
4. Now add the master (append ':SSL' to the address for https (respect the port!)):
    ```ini
    [stream]
        enabled = yes
        destination = [TARGET_ADDR]:[TARGET_WEB_PORT]
        api key = xxxxxxxx-xxxx-xxxxx-xxxx-xxxxxxxxxxxx
    ```

### Master ###
1. Edit the config: `sudo /opt/netdata/etc/netdata/edit-config stream.conf`
2. Now add the slave:
    ```ini
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

# Add Teleram bot notifications #
1. Edit the config with `sudo /opt/netdata/etc/netdata/edit-config health_alarm_notify.conf` and modify it so it contains:
    ```ini
    SEND_TELEGRAM="YES"
    TELEGRAM_BOT_TOKEN="[BOT_API_TOKEN]"
    DEFAULT_RECIPIENT_TELEGRAM="[TARGET_CHAT_ID]"
    ```
2. Done - test it ([see here at the end](https://docs.netdata.cloud/health/notifications/email/))

# How to mute a specific alarm #
One or more alarms are useless and can be ignored? Check out the source row at the dashboard (-> e.g. `sudo /opt/netdata/etc/netdata/edit-config health.d/...`). Go there and change the recipient from `to: [someone]` to `to: silent`. Or disable it by comment it with # out!

~ Finally: Quiet nights! ~

# How to prevent package drop warnings without muting the alarm #
1. Apply `sudo sysctl -w net.core.netdev_budget_usecs=6400 && sudo sysctl -w net.core.netdev_budget=600` as temporary fix. The alarm should now fade.
2. If that was successful: Apply them permanent in /etc/sysctl.conf by adding:
    ```
    net.core.netdev_budget_usecs=6400
    net.core.netdev_budget=600
    ```

# Nett2Know #
If you get much dbengine fs errors and can't add any more working instances to the netdata streaming config (the access.log is filled with `CANNOT ACQUIRE HOST`) you should [increase the file descriptor limit](https://github.com/netdata/netdata/blob/master/database/engine/README.md).

# Update (non-debian package only) #
```bash
sudo chmod +x /opt/netdata/usr/libexec/netdata/netdata-updater.sh && sudo /opt/netdata/usr/libexec/netdata/netdata-updater.sh
```

# Uninstall (non-debian package only) #
```bash
sudo chmod +x /opt/netdata/usr/libexec/netdata/netdata-uninstaller.sh && sudo /opt/netdata/usr/libexec/netdata/netdata-uninstaller.sh
```
