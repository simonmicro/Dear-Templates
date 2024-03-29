---
summary: Templates for reverse proxies with websocket support? Wildcards. And Docker stuff.
---

# Configuration

This is a simple config file for NGINX. You should note:
* `exception.example.com` forces HTTPS and is a reverse proxy.
* `*.example.com` is a HTTP/S reverse proxy respectively. 
* The HTTPS for `*.example.com` allows at most a 30 second delay / duration at responses. Additionally custom error pages are supported.
* All HTTPS variants are allowing WebSocket connections.
* In case you have DNS based endpoints... [READ THIS](https://github.com/DmitryFillo/nginx-proxy-pitfalls), it will save you HOURS!

```nginx
# At first: A good practice...
add_header X-Clacks-Overhead "GNU Terry Pratchett";
add_header X-Cat "😸";
client_max_body_size 256M; # Well, the default is somewhat small...
client_body_buffer_size 32M; # If the client body is greater than this it will be buffered by a file, which also causes warnings - the default is too small...
server_tokens off; # Nobody must know what potential security problems you have!

server {
    listen 80;
    server_name exception.example.com;

    return 301 https://exception.example.com$request_uri;
}

server {
    listen 443 ssl;
    server_name exception.example.com;

    ssl_certificate     /certs/cert.pem;
    ssl_certificate_key /certs/privkey.pem;

    location / {
        proxy_pass http://[REAL_URI];
        # Inform target host about proxy client...;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        # Support WebSocket connections...
        proxy_http_version 1.1; # Default is 1.0
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Optionally, use the exception rules from the wildcard example also for this...
}

server {
    listen 80 default_server;
    server_name *.example.com; # Note, you can use for "default_server" (like here) the invalid server name "_" instead

    location / {
        access_log off; # Do not enable this on every domain. Otherwise it will spam!
        proxy_pass http://[REAL_URI];
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 443 ssl default_server;
    server_name *.example.com; # Note, you can use for "default_server" (like here) the invalid server name "_" instead

    ssl_certificate     /certs/cert.pem;
    ssl_certificate_key /certs/privkey.pem;

    location / {
        access_log off; # Do not enable this on every domain. Otherwise it will spam!
        proxy_pass https://[REAL_URI];
        # Inform target host about proxy client...;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        # Wait for x seconds for the uplink...
        proxy_connect_timeout 30;
        proxy_send_timeout 30;
        proxy_read_timeout 30;
        send_timeout 30;
    }

    # The following are overrides to provide own error pages
    location /_error {
        access_log off;
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
