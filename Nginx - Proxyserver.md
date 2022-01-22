---
summary: Templates for reverse proxies with websocket support? Wildcards. And Docker stuff.
---

# Configuration

This is a simple config file for NGINX. You should note:
* `exception.example.com` forces HTTPS and is a reverse proxy.
* `*.example.com` is a HTTP/S reverse proxy respectively. 
* The HTTPS for `*.example.com` allows at most a 30 second delay / duration at responses. Additionally custom error pages are supported.
* All HTTPS variants are allowing WebSocket connections.

```nginxconf
server {
    listen 80;

    server_name exception.example.com;
    return 301 https://exception.example.com$request_uri;
}

server {
    listen 443 ssl;

    ssl_certificate     /certs/cert.pem;
    ssl_certificate_key /certs/privkey.pem;

    server_name exception.example.com;

    location / {
        access_log      off;
        proxy_pass http://[REAL_URI];
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # Support WebSocket connections...
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 80;

    server_name *.example.com;

    location / {
        access_log      off;
        proxy_pass http://[REAL_URI];
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 443 ssl default;

    ssl_certificate     /certs/cert.pem;
    ssl_certificate_key /certs/privkey.pem;

    server_name *.example.com;

    location / {
        access_log      off;
        proxy_pass https://[REAL_URI];
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # Wait for x seconds for the uplink...
        proxy_connect_timeout 30;
        proxy_send_timeout 30;
        proxy_read_timeout 30;
        send_timeout 30;
        # Support WebSocket connections...
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # The following are overrides to provide own error pages
    location /_error {
        root /usr/share/nginx/html;
    }
    error_page 404 /_error/404.html;
    location = /_error/404.html {
        root /usr/share/nginx/html;
        internal;
    }
    error_page 500 /_error/500.html;
    location = /_error/500.html {
        root /usr/share/nginx/html;
        internal;
    }
    error_page 502 /_error/502.html;
    location = /_error/502.html {
        root /usr/share/nginx/html;
        internal;
    }
    error_page 503 /_error/503.html;
    location = /_error/503.html {
        root /usr/share/nginx/html;
        internal;
    }
    error_page 504 /_error/504.html;
    location = /_error/504.html {
        root /usr/share/nginx/html;
        internal;
    }
}
```
...in case you want to use the error pages: Make sure to have a `404.html` and a `50x.html` inside the `_error` directoy, you could orient your page on [my own](https://gitlab.simonmicro.de/simonmicro/apache-defaults) ones.

# Docker
And just in case, as I'm lazy... Here is the needed compose file:
```yaml
version: '3'
services:
  nginx:
    image: nginx
    restart: always
    ports:
     - 80:80
     - 443:443
    volumes:
     - ./nginx.conf:/etc/nginx/conf.d/system.conf:ro
     - ./www:/usr/share/nginx/html:ro
     - ./certs/[PATH]/fullchain.pem:/certs/cert.pem:ro
     - ./certs/[PATH]/privkey.pem:/certs/privkey.pem:ro
```
