---
summary: Kubenetes services with external fixed ips using keepalived
---

# Exposed Services

## Desicion flowchart
```
Does the Deployment needs to be reachible on any port?
-> Yes. Proceed.
-> No? Done.

Does the Deployment needs to be externally reachible on HTTP/S?
-> Yes: Create a service and configure your ingress to use it (or instruct NGINX to proxy). Proceed.
-> No. Proceed.

Does the Deployment needs to be reachible on an other port by the cluster?
-> Yes: Create a service and configure your pods to use its DNS name. Proceed.
-> No. Proceed.

Does the Deployment needs to be reachible on an other port by external clients?
-> Yes: Create a service (e.g. LoadBalancer) with a NodePort. Proceed.
-> No. Proceed.

Does the Deployment needs to be reachible on an other port by external clients with the original clients ip visible?
-> Yes: Adapt the following YAML to your needs. Keep in mind to correctly configure the ip / interfaces (or skip keepalived if using a real external load-balancer). Done.
-> No. Done.
```

## YAML
This is the example configuration YAML-file. It will spin up a NGINX instance, which just replies the clients IP to test the transparency.
Keep in mind to change the external service ip (`192.168.0.100`) and incoming interface it should be assigned to (`enp6s0`), as well as the external port (`8080`).

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: service-with-external-ip
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: external-service-ip
  namespace: service-with-external-ip
spec:
  selector:
    matchLabels:
      name: external-service-ip
  template:
    metadata:
      labels:
        name: external-service-ip
    spec:
      hostNetwork: true
      containers:
      - name: keepalived
        image: arcts/keepalived
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
        env:
        - name: KEEPALIVED_INTERFACE
          value: "enp6s0"
        - name: KEEPALIVED_VIRTUAL_IPADDRESS_1
          value: "192.168.0.100/24 dev enp6s0"
        - name: KEEPALIVED_VIRTUAL_ROUTER_ID
          value: "100"
---
apiVersion: v1
kind: Service
metadata:
  name: external-service
  namespace: service-with-external-ip
spec:
  type: LoadBalancer
  selector:
    app: backend
  ports:
    - name: demo
      protocol: TCP
      port: 8080
      targetPort: 80
  externalIPs:
    - 192.168.0.100
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: service-with-external-ip
data:
  default.conf: |
    server {
        listen 80 default_server;
        server_name _;
        location / {
            return 200 $remote_addr;
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: service-with-external-ip
spec:
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: echo-ip
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /etc/nginx/conf.d/default.conf
          name: backend-config-volume
          subPath: default.conf
      volumes:
        - name: backend-config-volume
          configMap:
            name: backend-config
```

## In the Future...
...maybe this will work with `externalTrafficPolicy: Local`, as at some point Kubernetes will may support `requiredDuringSchedulingRequiredDuringExecution`.
This would allow `keepalived` to only run on pods on which the deployment is executed. An example affinity would look like this:

```yaml
      affinity:
        podAffinity:
          requiredDuringSchedulingRequiredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - nextcloud-media
            topologyKey: kubernetes.io/hostname
```

Currently with `requiredDuringSchedulingIgnoredDuringExecution` this won't work, as the `keepalived` instance is not moved in case the deployment gets evicted.

# Path serializer
In case you need a config map, which describes a whole folder...

```python
import os, re, sys, subprocess
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--volume', type=str, required=True, help='Name of volume and target YAML path')
parser.add_argument('--dir', type=str, required=True, help='Which path sould be serialized?')
parser.add_argument('--mountPath', type=str, required=True, help='Where should the serialized data go?')
args = parser.parse_args()

def makeSimplePath(p):
    return re.sub(r'-+', '-', re.sub(r'[^a-z0-9]', '-', p.lower()))
  
dirs = [args.dir]
for p,d,f in os.walk(args.dir):
    for dd in d:
        dirs.append(os.path.join(p, dd))

maps = []
for dd in dirs:
    print('Serializing path: ' + dd)
    maps.append([dd, subprocess.check_output(['kubectl', 'create', 'configmap', args.volume + '-files-' + makeSimplePath(dd), '--from-file=' + dd, '-o', 'yaml', '--dry-run=client'], ).decode()])

with open(args.volume + '.yml', 'w') as f:
    f.write(f'# This file was generated using: {" ".join(sys.argv)}\n')
    f.write('---\n')
    for m in maps:
        f.write(m[1])
        f.write('---\n')

print('Now append this to your YAML...')
print('volumeMounts:')
print(f'# Warning: All volumes beginning with "{args.volume}-files-" are generated automatically. Do not touch them!')
for m in maps:
    print('- name: ' + args.volume + '-files-' + makeSimplePath(m[0]) + '-volume')
    print('  mountPath: ' + os.path.join(args.mountPath, os.path.relpath(m[0], args.dir)))
    print('  readOnly: true')

print()
print('volumes:')
print(f'# Warning: All volumes beginning with "{args.volume}-files-" are generated automatically. Do not touch them!')
for m in maps:
    print('- name: ' + args.volume + '-files-' + makeSimplePath(m[0]) + '-volume')
    print('  configMap:')
    print('    name: ' + args.volume + '-files-' + makeSimplePath(m[0]))
```
