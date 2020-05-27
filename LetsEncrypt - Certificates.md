---
summary: A incredible complex setup guide...
---

# Setup #
[See](https://certbot.eff.org/lets-encrypt/debianbuster-apache)
1. `sudo apt-get install certbot python-certbot-apache`
2. `sudo certbot certonly --apache`
    * If `403 Forbidden` occures try run `sudo chmod o+rx /var/lib/letsencrypt`
3. Now update the apache conf file to use the new cert...

# Renewal #
...done automatically...
