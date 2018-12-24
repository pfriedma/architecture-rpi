#!/bin/bash
# Init the master, using flannel
# Assuming using wlan0, but if not, set your interface, or override
# the definition of SERVICE_IP
#INF=wlan0

# The internal network to use for the cluster
#CLUSTER_NETWORK="10.224.0.0/16"

# Get the IP of INF
# there is probably a flag to do this... whoops...
#IP=`ip a | grep $INF | awk '{ print $2 }' | cut -d : -f 2 | cut -d / -f 1 | tr -d '\040\011\012\015'`

# Override this if you want to expose the API somewhere else
#SERVICE_IP=$IP

echo "setting bridge options..."
echo "running sudo sysctl net.bridge.bridge-nf-call-iptables=1"
sudo sysctl net.bridge.bridge-nf-call-iptables=1


read -p "Press enter when ready or ^c to abort..."

echo "Running kubeadm init --token-ttl=0"
sudo kubeadm init --token-ttl=0
read -p "Please note the join token and ca-cert hash, copy it somewhere, and press enter when ready..."

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# Deploy flannel...
# Need to change references from amd64 to arm...
#echo "Deploying flannel..."
#curl -sSL https://rawgit.com/coreos/flannel/master/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -
echo "Deploying WeaveNet..."
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "Done!"

