---
title: CUPS - Printers
summary: HowTo unlock the web interface...
type: blog
banner: "/img/dear-templates/default.jpg"
---

# To unlock the webinterface #
...change in the config:

```
Listen localhost:631
```
->
```
Port 631
```

And disable the forbidden lock:
```
<Location />
...
</Location>
```
->
```
<Location />
  Allow all     
</Location>
```
