#!/bin/bash
sudo rm -rf /var/lib/glusterd*
sudo rm -rf /etc/glusterfs/*
sudo rm -rf /var/lib/heketi/*
sudo touch /var/lib/heketi/fstab

sudo systemctl stop loopback.service
sudo losetup -d /dev/loop0
sudo rm /var/gluster.img
sudo fallocate -l 15G /var/gluster.img
sudo systemctl start loopback.service

