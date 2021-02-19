---
summary: PPTP - an older VNP server, just as a side-note...
---

> Yes. The protocol itself is no longer secure, as cracking the initial MS-CHAPv2 authentication can be reduced to the difficulty of cracking a single DES 56-bit key, which with current computers can be brute-forced in a very short time (making a strong password largely irrelevant to the security of PPTP as the entire 56-bit keyspace can be searched within practical time constraints).

~ [Nasrus](https://security.stackexchange.com/questions/45509/are-there-any-known-vulnerabilities-in-pptp-vpns-when-configured-properly)

**Really. Take that seriously. PPTP should not be used anywhere except inside _secured_, _isolated_ and _local_ environments anymore!**

Install it with:
```bash
sudo apt install pptpd
```

Create a new config in `/etc/pptpd.conf`:
```
localip 10.8.0.1
remoteip 10.8.0.200-220
```

Add the users and passwords `/etc/ppp/chap-secrets`:
```
# Secrets for authentication using CHAP
# client        server  secret                  IP addresses
#vpnuser         *       pass123                 *
client1         pptpd   very_secure_password    10.8.0.2
client2         pptpd   very_secure_password    10.8.0.3
```

And add the upstream DNS servers in `/etc/ppp/pptpd-options`:
```
ms-dns 1.1.1.1
ms-dns 1.0.0.1
```

Need some more logs?
```bash
sudo tail -f /var/log/messages
```
-> [Reference](https://serverfault.com/questions/487379/pptpd-log-of-unsuccessful-authentication)

And finally activate the service:
```bash
sudo systemctl enable pptpd
sudo systemctl start pptpd
```

## [Further reference](https://www.digitalocean.com/community/tutorials/how-to-setup-your-own-vpn-with-pptp)
