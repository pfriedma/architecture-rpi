#!/bin/bash
# This script runs a temp registry on your local machine for images,
# port-forwards it to a raspberry pi node defined by TARGET_NODE, 
# builds the heketi image, then uploads it to the registry...
USER=pi
TARGET_NODE=raspberrypi-node2
echo "pulling and starting registry..."
docker run -d -p 5000:5000 --name registry registry:2
scp ./build_heketi_image.sh $USER@$TARGET_NODE:~/ 
ssh -R 5000:localhost:5000 $USER@$TARGET_NODE "cd ~ && sudo bash ~/build_heketi_image.sh" 
