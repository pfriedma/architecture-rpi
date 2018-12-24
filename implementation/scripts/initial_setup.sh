#!/bin/bash
# Initial setup for each node. Assumes raspbian, so modify if needed
# Ensures the system is up to date, 
# Installs needed packages (xfsprogs, gluster client, lvm, git, etc) and some 
# useful utilities like screen and vim 

# Print a warning...
echo "Before running this script, please make sure you've run raspi-config and set up the node's hostname, expanded the filesystem, and set the timezone (and other things you'd want to do like changing the default password)"
read -p "If you've done these things, press enter to continue or ^c to abort" 

echo "Checking for, and installing updates..."
sudo apt-get update && apt-get upgrade -y

echo "Installing initial dependencies..."
sudo apt-get install -y vim screen xfsprogs glusterfs-common glusterfs-client lvm2 git

# Install docker
echo "Installing docker..."
curl -sSL get.docker.com | sh && sudo grouped docker rap sudo usermod pi -aG docker

# Turn off swap (kubernetes doesn't like it
echo "Turning off swap and setting boot params; backup /boot/cmdline.txt will be placed in /boot/cmdline.txt-bak"

sudo dphys-swapfile swapoff && sudo dphys-swapfile uninstall && sudo update-rc.d dphys-swapfile remove

# Boot tweaks for enabling containers (needs cgroups)
sudo sed -i-bak -e 's/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/' /boot/cmdline.txt

# Get Kubernetes
echo "Installing kubernetes..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
  sudo apt-get update -q && \
  sudo apt-get install -qy kubeadm

# Make sure lvm modules are loaded
echo "Enabling kernel modules..."
sudo su
cat >> /etc/modules <<-EOF
dm_thin_pool
dm_mirror
dm_snapshot
EOF

read -p "Ready to reboot... press enter to restart or ^c to do any cleanup tasks, please remember to reboot before proceeding with other scripts"
sudo reboot

