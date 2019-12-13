To unlock the webinterface change in the config:

```
Listen localhost:631
```
->
```
Port 631
```

Und disable the forbidden lock:
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
