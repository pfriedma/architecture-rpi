#!/bin/bash
# for when you need to blast away the volumes and try again...
declare -a CLUSTERS=("raspberrypi-node0" "raspberrypi-node1" "raspberrypi-node2")
for node in "${CLUSTERS[@]}"
do
   scp clear_gluster.sh pi@$node:~/ 
   ssh pi@$node "bash ~/clear_gluster.sh"
done
