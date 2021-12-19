---
summary: How you can use port forwarding even behind NAT (which is commonly used on mobile networks), including an example for integration into UniFi Gateways and a guide for a classic VPN server for any amount of clients!
---

# What is this?
This little guide describes how you can use port forwarding even behind NAT (which is commonly used on mobile networks) and a guide for a classic VPN server for any amount of clients!

# Setup: Hardware
This guide requires (with some degree of variation) the following items:
* A VM somewhere with (fast) network access #sponsoredByEvolutionHost
* UniFi USG Pro 4
* A SIM card with an (unlimited) data plan, which is behind one or more NAT - so the noemal port forwarding won't work
* SIM card stick, I used [this](https://www.amazon.de/HUAWEI-E3372-Surfstick-microSD-Schwarz/dp/B011BRKPLE) which also has his own router firmware (so no special OS requirements) and does NAT. It also does not support port forwardings.
* Some old laptop with Linux, which passes the mobile network to the USB on a WAN port

# Setup: Software
OpenVPN - that's it. I tried to utilize Pritunl as it's easy to use and has a graphical UI, but it made only problems when I used it inside a docker environment - so it's possible to use it instead, but I opted to do everything from scratch anyways.

# How it is done
The used ips here:
* `10.8.0.0/24` VPN network
* `10.8.0.1` VMs IPv4 inside the VPN network
* `10.8.0.2` USGs IPv4 inside the VPN network
* `192.168.0.0/16` Network behind the USG
* `192.168.32.2` Webserver behind the USG

## Laptop (SIM modem)
This really depends on your specific stick and OS choice. Under Linux just insert the stick, wait until it assignes you an ip, open the webinterface and enter (& store) the pin and create a new network profile for the LAN port connected
with the USG. This should disable ipv6 when its not needed and select "share to other computers" for ipv4. Then make sure you check "connect when available", so it gets active on boot.

## VM
As first ensure the VM has ip(v4) forwarding enabled (otherwise the port forwarding service later on won't work):
```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
```

### Certificates
Create a new file `/tmp/openssl_server.cnf` with:
```
[v3_ca]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
```
This is needed for signing CSRs with these enhancements. Use ONLY these `keyUsages`, the USG will fail when more are allowed (`remote-cert-tls`)...

Now create everything needed for the server (when you already have a CA, you may want to adapt this accordingly):
```bash
openssl dhparam -out dh2048.pem 2048
openvpn --genkey --secret ta.key

openssl genrsa -out ca.key 2048 # Generate new private key
openssl req -new -days 3650 -x509 -key ca.key -out ca.crt -subj '/CN=root-ca'
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj '/CN=server'
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -extensions v3_ca -extfile /tmp/openssl_server.cnf
```

### OpenVPN server
Now intall `openvpn` and we prepare the `/etc/openvpn/server/server.conf` (make sure to modify the `ipp`, `status`, `subnet`, `ccd` and `port` when you plan to deploy multiple instances on one server):
```
dev tun42
client-to-client
topology subnet
server 10.8.0.0 255.255.255.0
cipher AES-256-CBC

# Which TCP/UDP port should OpenVPN listen on?
port 1194

# TCP or UDP server (the latter has a lower overhead)?
proto udp

# When using UDP: Inform clients when the server is going down.
explicit-exit-notify 1

# Server identity & encryption
;ca ca.crt
<ca>
[INSERT CONTENT OF ca.crt]
</ca>
;cert server.crt
<cert>
[INSERT CONTENT OF server.crt]
</cert>
;key server.key
<key>
[INSERT CONTENT OF server.key]
</key>

# Diffie hellman parameters.
;dh dh2048.pem
<dh>
[INSERT CONTENT OF dh2048.pem]
</dh>

# Store the dhcp ips for clients here...
ifconfig-pool-persist ipp.txt

# Read client specific settings from (disabled by default, as the path must exist!)...
;client-config-dir /etc/openvpn/ccd

# The keepalive directive causes ping-like messages to be sent back and forth over
# the link so that each side knows when the other side has gone down. Ping every 5
# seconds, assume that remote peer is down if no ping received during a 30 second
# time period.
keepalive 6 30

# For extra security beyond that provided by SSL/TLS, create an "HMAC firewall"
# to help block DoS attacks and UDP port flooding.
;tls-auth ta.key 0
<tls-auth>
[INSERT CONTENT OF ta.key]
</tls-auth>
key-direction 0

# Give up any special permissions on start (didn't work for me)...
;user nobody
;group nobody

# The persist options will try to avoid accessing certain resources on restart
# that may no longer be accessible because of the privilege downgrade.
persist-key
persist-tun

# Output a short status file showing current connections, truncated and rewritten
# every minute.
status openvpn-status.log

# Allow older TLS versions to allow the USG to connect
;tls-version-min 1.0

# Allow multiple connections using the same profile
;duplicate-cn

# Enter here the network behind a client, which you want to route to (this adds a new route on the server)...
;route 192.168.0.0 255.255.0.0

# Enter here the network on the vpn server (this adds a new route on the client and can also specified in the ccd configs)...
;push "route 192.168.0.0 255.255.0.0"

# Verify the clients keyUsages and extendedKeyUsages
remote-cert-tls client

# Set the appropriate level of log
# file verbosity.
#
# 0 is silent, except for fatal errors
# 4 is reasonable for general usage
# 5 and 6 can help to debug connection problems
# 9 is extremely verbose
verb 3

# Also log to a persistent file for auditing purposes (this file will get bigger
# and bigger, so make sure to clean it now and then)...
;log-append server.log

# Enable monitoring port for e.g. Netdata on localhost only. Only enable when needed.
;management 127.0.0.1 7505
```

_NOTE_: Append the following to also route the default route and therefore allow internet access over the VPN (you'll also may need the `forward_from_vpn_clients` service below):
```
push "redirect-gateway def1 bypass-dhcp"
```

_NOTE_: Append the following to also configure the clients dns over the VPN (you'll also may need the `forward_from_vpn_clients` service below):
```
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
```

Now activate the OpenVPN server (the stuff after the `@` is just passed trough to the `openvpn-server` service as argument):
```bash
sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service
sudo systemctl status openvpn-server@server.service
```

### CCD: Client Specific Configs
To extend the configs of the connecting clients add inside the `/etc/openvpn/ccd` folder a new file named by the CN inside the clients certificate with:
```
# Configure static IP (obviuosly no two clients should get the same)
ifconfig-push 10.8.0.2 255.255.255.0
# Configure the routed network(s) - similar to the server.conf
iroute 192.168.0.0 255.255.0.0
```

### Respect the CAs CRLs
In case you want to revoke a clients certificate instantly (without haveing them expireing naturally) you have to use CRLs (I already described their creation [here]({{< relref "OpenSSL - Certificates.md" >}})).
To insturct your OpenVPN server to respect a local copy of such a CRL just add the following:
```
crl-verify [PATH_TO_CA_CRL_FILE].crl
```

### Forward as vpn client - MASQUERADE
...this iy maybe needed when you plan to allow internet access over your vpn.

Create a new service under `/etc/systemd/system/forward_from_vpn_clients.service` (**make sure to modify `Requires=` if you use an other name or multiple instances**):
```systemd
[Unit]
Description=Enable NAT-based forwarding of requests from OpenVPN clients
Requires=openvpn-server@server.service

[Service]
Type=simple
RemainAfterExit=yes
Restart=on-failure
RestartSec=5s
ExecStart=/root/forward_from_vpn_clients.sh start
ExecStopPost=/root/forward_from_vpn_clients.sh stop

[Install]
WantedBy=multi-user.target
```

And the needed script under `/root/forward_from_vpn_clients.sh`:
```bash
#!/bin/bash
set -x
export VPN_INTERFACE=tun0

start() {
    # Fail on unclean returns...
    set -e
    
    iptables -t nat -A POSTROUTING -i $VPN_INTERFACE -j MASQUERADE
}

stop() {
    # Remove all the previously added rules again (same commands; just with -D instead of -A)...
    iptables -t nat -D POSTROUTING -i $VPN_INTERFACE -j MASQUERADE
}

case $1 in
  start|stop) "$1" ;;
esac
```

And enable the new service:
```bash
sudo chmod 700 /root/forward_from_vpn_clients.sh
sudo systemctl enable forward_from_vpn_clients.service
sudo systemctl start forward_from_vpn_clients.service
sudo systemctl status forward_from_vpn_clients.service
```

### Forward as vpn client - Policy based routing
This script can be used in place of the `MASQUERADE` versions above, as using `MASQUERADE` chooses their host-interface to do the NAT-ing in an unpredictable manner (bad if you plan to utilize an external firewall solution).
So, this script is build to route the requests from the VPN subnets over a specific network interface - note that we specify the default route, so any bad actor will be able to add additonal routes to be send over the vpn tunnel as he wishes.
This is the reason why I recommend to utilize an external firewall solution in conjunction with this script, as I chose to keep the script as-simple-as-possible and therefore did not added any packet filtering.

Add this to `/root/forward_vpn_clients.py`:
```python
#!/usr/bin/python3
import os
import sys
import ipaddress

config = {
    # VPN-Network in CIDR notation -> (Exit interface, Exit Interface Gateway (defaults to the first IP in the network if set to None))
    '10.8.0.0/24': ('eth0', None),
    '10.8.42.0/24': ('bond0.42', None),
    '10.8.100.0/24': ('bond0.100', None),
    '10.8.12.0/28': ('enp8', '192.168.0.1'),
}
policyTableBase = 100

'''
Policy based routing...
Step 1: Mark the packages from the network for the routing-policy
Step 2: Configure SNAT for the target interface, secured based on the source address
Step 3: Fill the routing-policy-table with the default route for the target interface
'''

def get_ip_address(ifname):
    # Returns tuple of (IP, Mask)
    return os.popen('ip addr show ' + ifname).read().split('inet ')[1].split(' ')[0].split('/')

if sys.argv[1] == 'start':
    for policyId in range(0, len(config.keys())):
        srcPrefix = list(config.keys())[policyId]
        dstInterface, dstGateway = config[list(config.keys())[policyId]]

        os.system('iptables -t mangle -A PREROUTING -s {} -j MARK --set-mark {}'.format(srcPrefix, policyId + policyTableBase))
        os.system('iptables -t nat -A POSTROUTING -s {} -o {} -j SNAT --to-source {}'.format(srcPrefix, dstInterface, get_ip_address(dstInterface)[0]))
        # For SNAT debugging try: sudo conntrack -E --event-mask NEW --any-nat
        os.system('ip route add table {} default via {} dev {}'.format(policyId + policyTableBase, ipaddress.IPv4Network('/'.join(get_ip_address(dstInterface)), False)[1] if dstGateway is None else dstGateway, dstInterface))
        os.system('ip rule add fwmark {} table {}'.format(policyId + policyTableBase, policyId + policyTableBase))
        os.system('ip route flush cache') # Trash everything before
elif sys.argv[1] == 'stop':
    for policyId in range(0, len(config.keys())):
        srcPrefix = list(config.keys())[policyId]
        dstInterface, _ = config[list(config.keys())[policyId]]

        os.system('iptables -t mangle -D PREROUTING -s {} -j MARK --set-mark {}'.format(srcPrefix, policyId + policyTableBase))
        os.system('iptables -t nat -D POSTROUTING -s {} -o {} -j SNAT --to-source {}'.format(srcPrefix, dstInterface, get_ip_address(dstInterface)[0]))
        os.system('ip route flush table {}'.format(policyId + policyTableBase))
        os.system('ip rule delete fwmark {}'.format(policyId + policyTableBase))
        os.system('ip route flush cache') # Trash everything before
elif sys.argv[1] == 'status':
    print('**** Table: mangle')
    os.system('iptables -t mangle -L PREROUTING -v')
    os.system('iptables -t nat -L PREROUTING -v')
    print('**** Route Rules:')
    os.system('ip rule show')
    for policyId in range(0, len(config.keys())):
        print('**** Route Table {}:'.format(policyId + policyTableBase))
        os.system('ip route show table {}'.format(policyId + policyTableBase))
    print('**** Table: nat')
    os.system('iptables -t nat -L POSTROUTING -v')
elif sys.argv[1] == 'add-log':
    # Are all routing-rules there? Does the NAT-ing work? Is the marking even enabled??? Add logging hooks to log into "dmesg".
    # Only use this if you REALLY need it - otherwise try "status" FIRST!
    for policyId in range(0, len(config.keys())):
        srcPrefix = list(config.keys())[policyId]
        dstInterface, _ = config[list(config.keys())[policyId]]
        os.system('iptables -t nat -I POSTROUTING 1 -s {} -o {} -j LOG --log-prefix "NAT for {}: "'.format(srcPrefix, dstInterface, dstInterface))
        os.system('iptables -t nat -A POSTROUTING -s {} -o {} -j LOG --log-prefix "NAT FAILED: "'.format(srcPrefix, dstInterface, dstInterface))
else:
    print('Unsupported operation.')
```

This script will _only mark_ the packages by default - you _have to enable ip forwarding to utilize the installed `SNAT` rules_! For that extend `/etc/systcl.conf` (and reboot the server):
```ini
net.ipv4.ip_forward = 1
```

Add this to `/etc/systemd/system/forward_vpn_clients.service`:
```systemd
[Unit]
Description=Enable forwarding as OpenVPN client(s)
Requires=openvpn-server@it.service openvpn-server@worker.service

[Service]
Type=simple
RemainAfterExit=true
Restart=on-failure
RestartSec=5s
ExecStart=/usr/bin/python3 /root/forward_vpn_clients.py start
ExecStopPost=/usr/bin/python3 /root/forward_vpn_clients.py stop

[Install]
WantedBy=multi-user.target
```

Activate it!
```bash
sudo systemctl enable forward_from_vpn_clients.service
sudo systemctl start forward_from_vpn_clients.service
sudo systemctl status forward_from_vpn_clients.service
```

### Port forwarding to vpn clients
Don't use `iptables-persistent`, it will also try to save `fail2ban` stuff (when installed)...

Create a new service under `/etc/systemd/system/forward_ports_to_vpn_clients.service` (**make sure to modify `Requires=` if you use an other name or multiple instances**):
```systemd
[Unit]
Description=Enable host port forwarding to other systems
Requires=openvpn-server@server.service

[Service]
Type=simple
RemainAfterExit=yes
Restart=on-failure
RestartSec=5s
ExecStart=/usr/bin/python3 /root/forward_ports_to_vpn_clients.py start
ExecStopPost=/usr/bin/python3 /root/forward_ports_to_vpn_clients.py stop

[Install]
WantedBy=multi-user.target
```

And the needed script under `/root/forward_ports_to_vpn_clients.py`:
```python
#!/usr/bin/python3
import os
import sys

config = {
    # Incoming port (any interface) -> (Target IP (may inside own VPN network), Target Port)
    80: ('192.168.2.14', 80),
    443: ('192.168.2.14', 443)
}

'''
Manual NAT to VPN clients...
1. Install DNAT rule(s) to (vpn) IPs
2. Setup masquerade to allow traffic back from DNAT IP
'''

if sys.argv[1] == 'start':
    for port, target in config.items():
        os.system(f'iptables -t nat -A PREROUTING -p tcp --dport {port} -j DNAT --to-destination {target[0]}:{target[1]}')
        os.system(f'iptables -t nat -A POSTROUTING -d {target[0]} -p tcp --dport {target[1]} -j MASQUERADE')
elif sys.argv[1] == 'stop':
    for port, target in config.items():
        os.system(f'iptables -t nat -D PREROUTING -p tcp --dport {port} -j DNAT --to-destination {target[0]}:{target[1]}')
        os.system(f'iptables -t nat -D POSTROUTING -d {target[0]} -p tcp --dport {target[1]} -j MASQUERADE')
        os.system('ip route flush cache') # Trash everything before
elif sys.argv[1] == 'status':
    print('**** Table: nat')
    os.system('iptables -t nat -L PREROUTING -v')
    os.system('iptables -t nat -L POSTROUTING -v')
else:
    print('Unsupported operation.')

```

And enable the new service:
```bash
sudo systemctl enable forward_ports_to_vpn_clients.service
sudo systemctl start forward_ports_to_vpn_clients.service
sudo systemctl status forward_ports_to_vpn_clients.service
```

## Clients
A little warning beforehand: It seems the Network Manager (commonly used on Ubuntu derivates) tends to assign the imported OpenVPN profile always the default route, which will break any other network communication.
To circumvent that just set the checkbox to use the network "only for local resources".

### Certificates
Create a new file `/tmp/openssl_clients.cnf` with:
```
[v3_ca]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
```
This is needed for signing CSRs with these enhancements. This WILL BE checked by the server, otherwise the clients connection will be rejected (`remote-cert-tls`)...
Generate the set of certificates for the clients with (make sure to change the names of the files!):
```bash
openssl genrsa -out [CLIENT_USERNAME].key 2048
openssl req -new -key [CLIENT_USERNAME].key -out [CLIENT_USERNAME].csr -subj '/CN=[CLIENT_USERNAME]'
openssl x509 -req -days 365 -in [CLIENT_USERNAME].csr -CA ca.crt -CAkey ca.key -CAcreateserial -out [CLIENT_USERNAME].crt -extensions v3_ca -extfile /tmp/openssl_clients.cnf
```

### Config(s)
This is the needed config file for every client - I recommend to first create a "test"-client (with a webserver to test the port forwarding stuff) before installing it to the USG!
```
client
dev tun
proto udp
resolv-retry infinite

# The hostname/IP and port of the server. You can have multiple remote
# entries to load balance between the servers.
remote [VPN_SERVER_HOST] 1194

# Allow the server to change its ip/port freely
float

# Most clients don't need to bind to a specific local port number.
nobind

# Give up any special permissions on start (didn't work for me)...
;user nobody
;group nobody

# The persist options will try to avoid accessing certain resources on restart
# that may no longer be accessible because of the privilege downgrade.
persist-key
persist-tun

# Client identity & encryption
;ca ca.crt
<ca>
[INSERT CONTENT OF ca.crt]
</ca>
;cert client.crt
<cert>
[INSERT CONTENT OF [CLIENT_USERNAME].crt]
</cert>
;key client.key
<key>
[INSERT CONTENT OF [CLIENT_USERNAME].key]
</key>
;tls-auth ta.key 1
<tls-auth>
[INSERT CONTENT OF ta.key]
</tls-auth>
key-direction 1
cipher AES-256-CBC

# For additional security: Do not store anything in RAM (this will may cause
# multiple password requests during the session)
auth-nocache

# Verify the servers keyUsages and extendedKeyUsages
remote-cert-tls server

# Set the appropriate level of log
# file verbosity.
#
# 0 is silent, except for fatal errors
# 4 is reasonable for general usage
# 5 and 6 can help to debug connection problems
# 9 is extremely verbose
verb 3
```

## Install on USG
Upload the client config for the USG to `/config/user-data/client_vtun0.ovpn`.
Just execute the following commands:
```bash
configure
set interfaces openvpn vtun0 config-file /config/user-data/client_vtun0.ovpn
commit;save;exit
```
When you don't want to use the previously described port forwarding service, you could also change the primary interface for the port forwardinds on the USG itself. For that use `set port-forward wan-interface vtun0` right before
commiting. Note that then all port forwardings _only_ work on that interface!
Now export the config with `mca-ctrl -t dump-cfg > /tmp/config` and search it for the modified sections. For me it only was:
```json
{
    "interfaces": {
        "openvpn": {
            "vtun0": {
                "config-file": "/config/user-data/client_vtun0.ovpn"
            }
        }
    }
}
```
This part must now be [installed](https://help.ui.com/hc/en-us/articles/215458888-UniFi-How-to-further-customize-USG-configuration-with-config-gateway-json) into the `config.gateway.json` on the controller.
Also make sure to add some firewall rules to prevent the VM to go on a rampage - just in case...

## Pushing own DNS servers
...works. Mostly. I know that Windows _should_ work and Android just does. There is a problem with Linux, as OpenVPN is not sure to use either the classic `resolvconf` or the newer Systemd-Resolvd. To solve that, the `.ovpn` profile
must include one of the following two solutions or be loaded using the Network Manager (which somehow always assigns the default route?!). They are both not perfect (`script-security` - brrr), but until OpenVPN does fixes that finally,
we have to deal with that on our own.

### Resolvconf
Just append:
```
# This needs some support on the client side (install openresolv) -> https://github.com/StreisandEffect/streisand/issues/1434#issuecomment-417792239
script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf
```

### SystemV
Just append:
```
# This needs some support on the client side (install openvpn-systemd-resolved) -> https://askubuntu.com/a/1036209/1065486
script-security 2
up /etc/openvpn/update-systemd-resolved
down /etc/openvpn/update-systemd-resolved
```
