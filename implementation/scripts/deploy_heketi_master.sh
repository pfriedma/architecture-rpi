#!/bin/bash
# Download, correct and install heketi on arm

# Set your nodes...
declare -a CLUSTERS=("raspberrypi-node0" "raspberrypi-node1" "raspberrypi-node2")

cd ~
# Get the distribution...
echo "Getting gluster-kubernetes..."
git clone https://github.com/gluster/gluster-kubernetes.git
cd gluster-kubernetes

# Fix references to heketi/heketi:dev with a version for the pi...
find ./ -type f -exec \
    sed -i 's/heketi\/heketi:dev/localhost:5000\/heketi/g' {} +


find ./ -type f -exec \
    sed -i 's/gluster\/gluster-centos:latest/localhost:5000\/gluster-fedora/g' {} +
    