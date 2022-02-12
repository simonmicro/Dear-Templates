---
summary: Kubenetes services with external fixed ips using keepalived
---

# Desicion flowchart
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
      - name: external-service-ip
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
  externalTrafficPolicy: Local
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
