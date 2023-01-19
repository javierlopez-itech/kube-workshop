# Just enough Kubernetes

```
~~~figlet Just Enough Kubernetes

~~~
```

SRE Tribe - Winter 2023

---

# Just enough Kubernetes

## Workshop requirements

- IAM AWS account on NetManagment 
- aws CLI
- kubectl

## Pre-flight checks

```bash
# ~/.aws/credentials
[default]
aws_access_key_id=<your-access-key>
aws_secret_access_key=<your-secret-key>
```

* * *

```bash
# ~/.aws/config
[default]
output=json

...

[profile workshop]
role_arn = arn:aws:iam::253271932012:role/k8s_workshop_role
role_session_name = <your-email-address>
mfa_serial=arn:aws:iam::253271932012:mfa/<your-email-address>
source_profile = default
```

If you don't have your AWS credentials
```
https://us-east-1.console.aws.amazon.com/iam/home#/users/<your-email-address>
```

---

# YAML 101

## Array

```yaml
fruits: [Apple, Orange, Strawberry]
```

* * *

```yaml
fruits:
- Apple
- Orange
- Strawebeery
```

---

# YAML 101

## Objects

```yaml
person: { name: "John", age: 30 }
```

* * *

```yaml
person:
  name: "John"
  age: 30
```

---

# YAML 101

## Arrays of Objects

```yaml
people:
- { name: "John", age: 30 }
- { name: "Alice", age: 25 }
```

* * * 

```yaml
people:
- name: "John"
  age: 30
- name: "Alice"
  age: 25
```

* * *

```yaml
people:
- 
  name: "John"
  age: 30
- 
  name: "Alice"
  age: 25
```

---

# What is Kubernets?

Kubernetes is an **container orchestration framework**

It will help us with:
- High Availability
- Scalability
- Disaster Recovery
- Authentication & Authorization
- Resource Allocation
- Monitoring

---

# Interacting with Kubernetes

Kubernetes provides a RESTful API (APIServer).

We interact with Kubernetes sending HTTP API requests to the APIServer (GET, POST, PUT, PATCH, DELETE)

`kubectl` is a CLI tool that provides an easier way to interact with this HTTP API.

### HTTP API way

```bash
curl -XGET https://cluster.info/api/v1/namespaces/default/pods
```

```bash
curl -XPOST https://cluster.info/api/v1/namespaces/default/pods -d @pod.yaml
```

### Kubectl way
```bash
kubectl get pods -n default
```

```
kubectl create pod -f "pod.yaml"
```

---

# Interacting with Kubernetes

Copy the contents of this file to `~/.kube/config`

```yaml
~~~./cluster/generate_kubeconfig.sh

~~~
```

---

# Interacting with Kubernetes

## Terminal Users

For those of you keen on using the **terminal**

```bash
export KUBECONFIG=~/.kube/config
kubectl config set-context --current --namespace=javier-lopez
```

```
~~~./dub.sh kubectl cluster-info

~~~
```

* * *

## GUI Users

For those of you that prefer **GUIs**

`https://afaad3f0fa928432487e61bc9ef0ad8b-1311168990.eu-north-1.elb.amazonaws.com/`

And generate a token

```
aws eks get-token --region=eu-north-1 --cluster=k8s-workshop --profile=workshop
```

```bash
~~~./jq.sh aws eks get-token --region=eu-north-1 --cluster=k8s-workshop --profile=workshop

~~~
```


---

# Pods

## What is a Pod?

- Abstraction over a container
- A collection of containers (usually just one)
- Each pod (not container) gets and IP address
- Share the same network
- Filesystem is not shared

* * *

```yaml
~~~cat basic-pod.yaml

~~~
```

---

# Pods

## Creating our first Pod

Terminal: `watch -n 1 kubectl get pods`

```bash
kubectl apply -f basic-pod.yaml
sleep 2
```

```bash
minikube ssh 'docker ps --filter "name=podinfo"'
```

---

# Pods

## Self-healing

Terminal: `minikube ssh 'docker kill <container-id>'`

---

# Pods

## Networking

Each Pod is given an IP address

```bash
~~~./dub.sh kubectl get pods -o wide

~~~
```

* * *

This IP is local and only reachable within the node

Terminal: `minikube ssh 'curl http://<pod-ip>'`

* * *

It can also forward to your localhost using `port-forward`

Terminal: `kubectl port-forward pod/podinfo 9898:9898`

---

# Pods

## Getting Pod information

```bash
kubectl describe pod/podinfo
```

---

# Pods

## Deleting our Pod

```bash
kubectl delete -f basic-pod.yaml
```

---

# Deployments
Think of a deployment as a set of similar pods.

## Benefits of deploy
- Scalability
- Helps with rolling out/back strategies
- Pod updates

* * *

```yaml
~~~cat basic-deployment.yaml

~~~
```

---

# Deployments

## Creating our first deployment

Terminal_1: `watch -n 1 kubectl get pods`

Terminal_2: `watch -n 1 kubectl get deploy`

```bash
kubectl apply -f basic-deployment.yaml
kubectl get pods,deploy,replicasets
```

---

# Deployments

## Self-healing
If one of the pods for a deployment is deleted, the deployment controller will inmediatly create a new one.

```bash
POD_NAME=$(kubectl get pods -l app=podinfo -o go-template='{{ (index .items 0).metadata.name }}')
echo $POD_NAME
kubectl delete pod $POD_NAME
```

---

# Deployments

## Scaling up/down deployments
If one of the pods for a deployment is deleted, the deployment controller will inmediatly create a new one.

```bash
kubectl scale --replicas=2 deploy/podinfo-deployment
```

---

# Deployments

## Rolling out a new version

Let's see what happens when we upgrade our application.

```bash
kubectl set image deploy/podinfo-deployment podinfo=stefanprodan/podinfo:6.1.3
```

---

# Deployments

## Deleting a deployment

```bash
kubectl delete deploy/podinfo-deployment
```

---

# Services

## What are services?
- Network layer for Pods
- Load-balancing capabilities (just round robin)
- Three types of services: _ClusterIP_, _NodePort_, _LoadBalancer_

---

# Services

## ClusterIP

Creates an internal service only available within the cluster.

```yaml
~~~cat service-clusterip.yaml

~~~
```

---

# Services

## ClusterIP: Creating the service

```bash
kubectl apply -f service-clusterip.yaml
kubectl get svc,endpoints -o wide
```

---

# Services

## ClusterIP: Networking

Services can be accessed:
- Using the IP address
- Using the service name (if both network interfaces are in the same namespaces)
- Using the fully qualified service name (_service-name.namespaces.svc.cluster.local_)

* * *

Terminal: `kubectl run curl-debug --rm -i --tty --restart=Never --image=radial/busyboxplus:curl -- /bin/sh`

---

# Services

## ClusterIP: Delete

```bash
kubectl delete svc/podinfo-svc-clusterip
```

---

# Services

## NodePort

Creates an internal service accessible via an external port

```yaml
~~~cat service-nodeport.yaml

~~~
```

---

# Services

## NodePort: Creating the service


```bash
kubectl apply -f service-nodeport.yaml
kubectl get svc,endpoints -o wide
```

---

# Services

## ClusterIP: Networking

Services can be accessed:
- Using the IP address
- Using the service name (if both network interfaces are in the same namespaces)
- Using the fully qualified service name (_service-name.namespaces.svc.cluster.local_)
- Using one of the Node IPs (private or public) on the *NodePort*

* * *

Terminal_1: `curl -s http://$(minikube ip):32100`

Terminal_2: `kubectl run curl-debug --rm -i --tty --restart=Never --image=radial/busyboxplus:curl -- /bin/sh`

---

# Services

## NodePort: Delete

```bash
kubectl delete svc/podinfo-svc-nodeport
```

---

# Liveness and Readiness Probes

- _Liveness probe_ - When to restart a container
- _Readiness probe_ - When to send traffic to a container
- Help Services make better decissions
- Defined per container (not Pod)

---

# Liveness and Readiness probes

```yaml
~~~cat deployment-with-probes.yaml

~~~
```

---

# Liveness and Readiness Probes

## Not ready pods

Terminal 1: `watch -n 1 kubectl get pods`

Terminal 2: `watch -n 1 kubectl get endpoints`

```bash
POD_NAME=$(kubectl get pods -l app=podinfo -o go-template='{{ (index .items 0).metadata.name }}')
echo $POD_NAME
kubectl exec $POD_NAME -- podcli check http --method=POST localhost:9898/readyz/disable
```

---

# Resource Request and Limits

- Tells the control plane your workload requirements
- _Request_: What the container is guaranteed to get
- _Limits_: What the container should never exceed
- Per container (not Pod)

---

# Resource Request and Limits

```yaml
~~~cat deployment-with-resources.yaml

~~~
```

---

# Resource Request and Limits

## Forcing a scheduler rejection

Terminal: `watch -n 1 kubectl get pods`

```
kubectl apply -f deployment-with-resources.yaml
```

Terminal: `kubectl scale --replicas=10 deployment/podinfo-deployment`

