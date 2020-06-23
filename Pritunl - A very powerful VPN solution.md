---
summary: How to use properly setup pritunl on debian buster
---

> I would recommend to use the docker image directly, because updates are applied that way much faster. But if you absolutly must - here you go...

# HowTo use pritunl... #
...or how to install on debian buster (make sure to also checkout [this neat helper](https://gitlab.simonmicro.de/simonmicro/pritunl-fake-api))...

```bash
sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list << EOF
deb https://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main
EOF

sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb https://repo.pritunl.com/stable/apt buster main
EOF

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
sudo apt-get update
sudo apt-get --assume-yes install pritunl mongodb-org-server
sudo systemctl start mongod pritunl
sudo systemctl enable mongod pritunl
```
(shamelessly fixed and commited to [here](https://docs.pritunl.com/docs/installation) and [here](https://github.com/pritunl/pritunl))
...If the key is missing: Just rerun the apt-key command with the shown digits...

## Change the web interface port ##
with `pritunl set app.server_port [NEW_PORT]` on the console.

## Client setup ##
Make sure to have the openvpn packages (also the ones for gnome!) installed.
