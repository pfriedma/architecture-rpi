#!/bin/bash
# Initialize cluster nodes...
# Set your join command
JOIN_CMD="the kubeadm join command printed out by kubeadm init"

echo "iptables bridge..."
sudo sysctl net.bridge.bridge-nf-call-iptables=1

echo "Joining cluster..."
sudo $JOIN_CMD 

echo "Done!"
