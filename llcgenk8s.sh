#!/bin/bash
#
if [ $# != 2 ]; then
  echo "usage: llcgenk8s.sh <tenant name> <# worker nodes>"
  exit 1
fi

tenant=$1
numWorkers=$2

[ -d k8s-${tenant} ] || mkdir k8s-${tenant}

cat >k8s-${tenant}/01-deploy-k8s-${tenant}.sh <<-EOF
#!/bin/bash
# Kubernetes Deployment Kick-Starter

model=\`juju list-models |awk '{print \$1}'|grep k8s-${tenant}\`
if [[ \${model} == "k8s-${tenant}" ]]; then
    echo "Model k8s-${tenant} already exists. Exiting..."
    exit 1
else
    juju add-model k8s-${tenant}
    juju switch k8s-${tenant}
    juju deploy k8s-${tenant}.yaml
fi

echo "Login to the juju-gui to see status or use juju status"
juju gui --no-browser --show-credentials
exit 0
EOF

chmod 755 k8s-${tenant}/01-deploy-k8s-${tenant}.sh

cat >k8s-${tenant}/02-destroy-k8s-${tenant}.sh <<-EOF
#!/bin/bash
# Destroy Kubernetes
set -ex

model=\`juju list-models |awk '{print \$1}'|grep k8s-${tenant}\`
if [[ \${model} == "k8s-${tenant}" ]]; then
    echo "Model:k8s-${tenant} Found -> Destroy in Progress!"
    juju destroy-model "k8s-${tenant}" -y
else
    echo "Model:k8s-${tenant} NOT Found! Exiting..."
    exit 1
fi
exit 0
EOF

chmod 755 k8s-${tenant}/02-destroy-k8s-${tenant}.sh

cat >k8s-${tenant}/k8s-${tenant}.yaml <<-EOF
series: xenial
services:
  easyrsa:
    annotations:
      gui-x: '450'
      gui-y: '550'
    charm: cs:~containers/easyrsa-50
    num_units: 1
    to:
      - "0"
  etcd:
    annotations:
      gui-x: '800'
      gui-y: '550'
    charm: cs:~containers/etcd-96
    options:
      channel: 3.2/stable
    num_units: 1
    to:
      - "0"
  flannel:
    annotations:
      gui-x: '450'
      gui-y: '750'
    charm: cs:~containers/flannel-66
    resources:
      flannel-amd64: 3
  kubeapi-load-balancer:
    annotations:
      gui-x: '450'
      gui-y: '250'
    charm: cs:~containers/kubeapi-load-balancer-69
    expose: true
    num_units: 1
    to:
      - "0"
  kubernetes-master:
    annotations:
      gui-x: '800'
      gui-y: '850'
    charm: cs:~containers/kubernetes-master-122
    num_units: 1
    options:
      channel: 1.11/stable
      allow-privileged: "true"
    to: 
      - "0"
  kubernetes-worker:
    annotations:
      gui-x: '100'
      gui-y: '850'
    charm: cs:~containers/kubernetes-worker-138
    constraints: cores=4 mem=4G
    expose: true
EOF

echo "    num_units: ${numWorkers}" >> k8s-${tenant}/k8s-${tenant}.yaml

cat >>k8s-${tenant}/k8s-${tenant}.yaml <<-EOF
    options:
      channel: 1.11/stable
      allow-privileged: "true"
    to:
EOF

for i in $(seq 1 ${numWorkers}); do
    echo "      - \"$i\"" >> k8s-${tenant}/k8s-${tenant}.yaml
done

cat >>k8s-${tenant}/k8s-${tenant}.yaml <<-EOF
relations:
- - kubernetes-master:kube-api-endpoint
  - kubeapi-load-balancer:apiserver
- - kubernetes-master:loadbalancer
  - kubeapi-load-balancer:loadbalancer
- - kubernetes-master:kube-control
  - kubernetes-worker:kube-control
- - kubernetes-master:certificates
  - easyrsa:client
- - etcd:certificates
  - easyrsa:client
- - kubernetes-master:etcd
  - etcd:db
- - kubernetes-worker:certificates
  - easyrsa:client
- - kubernetes-worker:kube-api-endpoint
  - kubeapi-load-balancer:website
- - kubeapi-load-balancer:certificates
  - easyrsa:client
- - flannel:etcd
  - etcd:db
- - flannel:cni
  - kubernetes-master:cni
- - flannel:cni
  - kubernetes-worker:cni
machines:
  "0":
    series: xenial
    constraints: arch=amd64 tags=mymachinetag-master
EOF

for i in $(seq 1 ${numWorkers}); do
    echo "  \"$i\":" >> k8s-${tenant}/k8s-${tenant}.yaml
    echo "    series: xenial" >> k8s-${tenant}/k8s-${tenant}.yaml
    echo "    constraints: arch=amd64 tags=mymachinetag-worker" >> k8s-${tenant}/k8s-${tenant}.yaml
done

echo "Completed generation of deployment scripts in subdir k8s-${tenant} ..."
exit 0



