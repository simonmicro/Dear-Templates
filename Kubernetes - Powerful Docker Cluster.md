---
summary: Kubenetes services with external fixed ips using keepalived
---

# Terms
* `volume`: A target for data storage - can be anything e.g. NFS, local disk, etc.
* `service`: Describes what ports are reachible how on which deployment / container
* `deployment`: Describes a set of `containers` that are deployed on a single host - commonly represented by a pod in kubernetes
* `pod`: "namespace for `containers`" - similar to a docker-compose stack
* `node`: physical / vm machine with a set of `pods`
* `container`: Similar to a docker container

# Setup
## Minicube
...good for first trys. It installs `kubectl` and `kubeadm` with a single node inside a "vm".

## Bare metal install (setup both client+server)

### Install (all machines)
-> https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
```

#### `kubeadm` with all dependencies
```bash
sudo apt-get install -y kubelet kubeadm kubectl docker.io
sudo apt-mark hold kubelet kubeadm kubectl # Freeze packages to prevent accidantial updates
```

#### Fix `cgroup` driver
-> https://phoenixnap.com/kb/how-to-install-kubernetes-on-a-bare-metal-server

```bash
sudo bash
cat > /etc/docker/daemon.json <<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
"max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF
```

### Create a cluster!
```bash
sudo kubeadm init --pod-network-cidr=10.111.0.0/16 --apiserver-advertise-address [CLUSTER_MASTER_IP]
```

You must then run these commands to retrive the kubeconfig file and token.
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### Install networking add-on
Using Flannel as network addon (no `sudo` anymore!) - more information is available [here](https://github.com/flannel-io/flannel/tree/master/Documentation):

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

Changed the configmap `kube-flannel-cfg` inside namespace `kube-system` and set `net-conf.json` to:
```
{
  "Network": "10.111.0.0/16",
  "EnableIPv6": false,
  "Backend": {
    "Type": "vxlan",
    "GBP": true,
    "DirectRouting": true
  }
}
```
It would be interesting to use other backends - like Wireguard at some point. This is especially needed in distributed setups.

#### Install metrics collector
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml
```
You see this error in the logs? https://github.com/kubernetes-sigs/metrics-server/issues/196
Solve it by introducing [certificates into the cluster](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#kubelet-serving-certs):

```bash
export EDITOR=nano
kubectl edit configmap/kubelet-config-1.23 -n kube-system
```

Make sure to run from time to time:
```bash
sudo kubeadm certs check-expiration
sudo kubeadm certs renew all
```

### Join workers
```bash
sudo kubeadm join [CLUSTER_MASTER_IP]:6443 --token 2ze2pr.a0z1IhfA3kdacqd7 --discovery-token-ca-cert-hash sha256:62e03606c3e4fee86bd016915283e8761a30a5b6b93219faad7547c5eca71c29
```
You can get the command again using this: https://stackoverflow.com/a/71137163/11664229

## Extend certificate names
This is needed if you plan to connect to your masters using e.g. their CNAMEs instead of their IP addresses (required by the Lens IDE).

-> https://blog.scottlowe.org/2019/07/30/adding-a-name-to-kubernetes-api-server-certificate/

## Helm
-> https://helm.sh/docs/intro/install/#from-apt-debianubuntu

## Unbalanced cluster
The problem is described there: https://itnext.io/keep-you-kubernetes-cluster-balanced-the-secret-to-high-availability-17edf60d9cb7

Add it to your cluster:
```bash
helm repo add descheduler https://kubernetes-sigs.github.io/descheduler/
helm install descheduler --namespace kube-system descheduler/descheduler
```

Now upgrade the release as you wish using the [`values.yml`](https://github.com/kubernetes-sigs/descheduler/blob/master/charts/descheduler/values.yaml).

## keel.sh
This is useful for automatic updates of pods (and their container images).
-> https://keel.sh

# Dashboard?!
If you really want it... There you go:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
kubectl proxy --address='0.0.0.0' --accept-hosts='.*'
```

## Create new admin user
Add to new file `dashboard-adminuser.yaml`:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
```

### Apply
```bash
kubectl apply -f dashboard-adminuser.yaml
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard
```

### Password?
```bash
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
# OR
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep kubernetes-dashboard | cut -d " " -f1)
```


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
            add_header Content-Type text/html;
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

Currently with `requiredDuringSchedulingIgnoredDuringExecution` this won't work, as the `keepalived` instance is not moved in case the deployment gets evicted. If you really need this take a look into the `descheduler` project...

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
