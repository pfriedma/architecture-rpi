# Scripts to help?

## Build_heketi_image.sh
A script to build Heketi in alpine for the raspberry pi, ahd push it to a container registry running on localhost:5000

## build_heketi_wsmonitor.sh
A script to orchistrate running the registry on your workstation, pushing the build script to a node, and building

## clear_gluster.sh
A script which deletes and re-creates the loopback devices in cases where the heketi deployment fails miserably

## init_vfs_loopback.sh
A script to create the loopback image, bind it to /dev/loop0 and create a systemd script to make sure it's always there

## initial_setup.sh
A script to update the system, install dependencies, and get things ready

## master_init.sh 
A script to bring up the master

## node_init.sh 
A script to join a node (useless :P)

## pi_pre_setup.sh
Run on your local machine (with the sd card) to set up wifi and ssh the first time

# reset_nodes_hkgluster.sh
Loop through your nodes and run clear_gluster.sh