# Architecture Reference Implementation
This is a reference implementation of the architecture built on Raspberry PI 3s, using raspbain, Kubernetes, WeaveNet networking and Heketi/Gluster hyperconverged storage (Heketi / Alpine, Geluster-Storage Fedora)

Thanks to the amazing work done by Hypriot, and [Deploying a RPI cloud](https://kubecloud.io/setting-up-a-kubernetes-1-11-raspberry-pi-cluster-using-kubeadm-952bbda329c8)

I wanted to explore the idea (and limitations of) distributed, mesh, hyperconverged infrastructure, so I did this entirely using the wireless capabilities of the RPI. You probably want to use ethernet for realz, so modify the `INF=wlan0` value in `scripts/master_init.sh`.

## A note about environments
I did this all on a mac, so you may need to slightly modify the scripts and paths (e.g. `/Volues/boot`)

## A note on Swap
After building the first time, I noticed the nodes were perpetually experienceing high iowait. Turns out on the limited resources of the PI, if you're going to start with a "default-distribution" like raspbain, you really want swap even though Kubernetes doesn't like it. Certain operations, like mirroring the gluster volumes, really benefit from some additional swap.

There is a version of the initial setup `scripts/initial_setup_wswap.sh` which DOESN'T turn off swap. 

After you run it, you need to edit the kubelet systemd script in `/etc/systemd` and append `--fail-swap-on=false` to the kubelet arguments on all nodes. 


## Overview
We'll rely on the fact that raspbian comes up initially with the fixed hostname 'raspberrypi' and we'll do the following:
1. Flash the image to the sd card
1. Set up initial /boot files
1. run `raspi-config` to get the node ready
     * Set the hostname raspberrypi-nodeN
     * Configure Timezone
     * Expand filesystem
1. Install kubernetes
1. Install WeaveNet
1. Bring up the other nodes
1. Build and Install Heketi and Gluster images
1. Deploy Heketi and Gluster

## Perform Initial Setup the Nodes
This setup all uses the stock raspbian image. I originally wanted to use Centos but the ARM support was iffy.

### Prepare nodes for PXE (Optional)
I wanted to eventually enable the nodes for netbooting to allow for dynamic scaling. The implementation is "future-phase", but in order to configure a RaspBerryPI to support this, you need to set a hardware flag
This step is optional, and you can skip

1. Flash the node in your usual way, (e.g. using e.g. BalenaEtcher)
1. cd /path/to/sd/boot/filesystem
1. echo program_usb_boot_mode=1 >> config.txt 
1. sync, unmount the sd card, and put it in the PI. Power it on, wait a bit, then you can take it out, and put it in each other PI to set the boot flag. 
1. Repeat as needed for each node

Once all the nodes have had their boot mode programmed, you can re-flash it with your chosen node OS, and proceed to the next step...
If you have an extra, small-capacity SD card sitting around you might want to save this for eventually adding new nodes...

### Setup Wireless (optional)
The Raspberry PI 3 comes with built in wifi (woo), if you're interested in exploring mesh hyperconverged infrastructure, you can built the entire cluster this way.

1. mount the boot filesystem of the sd card
2. enable Wireless
~~~~
cd /Volumes/boot
cat > wpa_supplicant.conf <<- EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
     ssid="your_ssid"
     psk="your wireless password"
}
EOF
~~~~
### Seup SSH

~~~~
cd /Volumes/boot 
touch ssh
~~~~


### Log into the node and configure
~~~~
ssh pi@raspberrypi
pi@raspberrypi:~ $ sudo raspi-config
~~~~
You'll want to set up the hostnames like:
* raspberrypi-node0
* raspberrypi-node1
* etc

Then set up user password(s), timezone, and finally, expand the root filesystem and reboot.

If you choose a differnt naming scheme, change the `CLUSTERS` array in the scripts to match.

### Get each node ready
The script `scripts/initial_setup.sh` performs the following steps:
1. update system
1. install packages
1. set up cgroup boot options
1. setup up docker and kubernetes repo
1. install kubernetes
1. enables `dm_thin_pool`, `dm_mirror`, and `dm_snapshot` kernel modules

copy this script to each PI and run.

### Install SSH keys
Doing this makes communicating with the nodes a lot easier
1. Create an ssh keypair with `ssh-keygen` (e.g. `ssh-keygen -f ~/.ssh/id_rsa_raspberrypi`)
1. Copy the public key to each node (e.g. `scp ~/.ssh/id_rsa_raspberrypi.pub  pi@raspberrypi-nodeN:~/.ssh/authorized_keys`)

## Install Kubernetes
Basically, follow [These Steps](https://kubecloud.io/setting-up-a-kubernetes-1-11-raspberry-pi-cluster-using-kubeadm-952bbda329c8)

The script in `scripts/master_init.sh` performs the following steps:

1. Sets `net.bridge.bridge-nf-call-iptables=1`
1. Runs `kubeadm init`
1. Applies WeaveNet networking


### Set up each node
This step is pretty straight forward:
1. Save the `kubeadm join` command from the previous step
1. `scp` the kubadm config from the master to each node (e.g. `scp $HOME/.kube/config pi@raspberrypi-nodeN:~/`)
2. `ssh` into each node and do the following:
~~~~
pi@raspberrypi-node1:~ $ mkdir -p $HOME/.kube
pi@raspberrypi-node1:~ $ mv config $HOME/.kube/
pi@raspberrypi-node1:~ $ sudo chown $(id -u):$(id -g) $HOME/.kube/config
~~~~
4. run `sudo sysctl net.bridge.bridge-nf-call-iptables=1`
5. Finally, run the join command as copied in step 1

It takes a few moments for the nodes to join, but if you go back on the master (node0 and run `kubectl get nodes`) you can see if they're ready - if all goes well you should see:
~~~~
pi@raspberrypi-node0:~ $ kubectl get nodes
NAME                STATUS   ROLES    AGE    VERSION
raspberrypi-node0   Ready    master   10m    v1.13.1
raspberrypi-node1   Ready    <none>   119s   v1.13.1
raspberrypi-node2   Ready    <none>   80s    v1.13.1
pi@raspberrypi-node0:~ $
~~~~

### Wrapping up Kubernetes config
The kubernetes dashboard is decent way to see your cluster status at a glance. The default .yaml uses amd64, but you can install it by doing:
~~~~
curl -sSL https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml | sed "s/amd64/arm/g" | kubectl apply -f -
~~~~

You can then create an admin user (not for prod!) by creating an admin service account:
~~~~
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
  ~~~~

  getting it's token with 
  `kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')`

  and then using it to log into the dashboard.



## Configuring GlusterFS and Heketi
The next step is configure our hyperconverged storage. We'll do the following. We'll use a loopback fs because partitioning the SD cards can suck, and we'll expand it later with additional disks (phase 2?)

### Prepare devices
The script `scripts/init_vfs_loopbash.sh` will do the folliwing:

1. Set up a loopback file to back the storage (15G)
2. Configure a systemd script to make sure it's available at `/dev/loop0` on boot.

~~~~
pi@raspberrypi-node0:~ $ sudo bash init_vfs_loopback.sh
creating a file of size 15G at /var/gluster.img
Creating loopback service in /etc/systemd/system
Calling systemctl daemon-reload and running the loopback service...
Done!
pi@raspberrypi-node0:~ $ losetup
NAME       SIZELIMIT OFFSET AUTOCLEAR RO BACK-FILE        DIO
/dev/loop0         0      0         0  0 /var/gluster.img   0
~~~~

### Build Heketi
This step was probably the most annying. As of writing this Readme, heketi-cli hardcodes the image name in its code :( . 

There are two scripts:
* `/scripts/build_heketi_image` will run on a raspberry pi of your choosing (I suggest node2)
* `/scripts/build_heketi_wsmonitor` will run a locker docker image registy on your machine, copy the build script to the node, ssh with port forwarding to the registry, and run the build script. 

Heketi's repo has [Cross Compile Ability](https://github.com/heketi/heketi/tree/master/extras/docker/rpi) if you want to use that instead. You'll need a local go build environment, but it's probably a lot faster.

1. Run `/scripts/build_heketi_wsmonitor` and wait a while..

This script will also change all references in the code from heketi:dev to localhost:5000/heketi. This means you'll need to ensure you have port 5000 on each node fowarded to wherever the image repo is. Eventually, we'll replace the registry with a real one running in the cluster.

### Build gluster images
On another node (you can do this while heketi is building), clone the [Gluster Container Repo](https://github.com/gluster/gluster-containers.git) and build gluster-fedora (remove the references to amd64 in the dockerfile)

Assuming you've got the registry from the above step running:
~~~~
ssh -R 5000:localhost:5000 pi@raspberrypi-node1

git clone https://github.com/gluster/gluster-containers.git
....
cd gluster-containers
docker build -t localhost:5000/gluster-fedora Fedora
docker push localhost:5000/gluster-fedora
~~~~

### Sync the images to each node
On each node:
1. `sudo docker pull localhost:5000/gluster-fedora`
1. `sudo docker pull localhost:5000/heketi`

### Prepare for Heketi Deployment

On the master:
1. Create a namespace for storage
~~~~
$ kubectl create namespace kube-storage
namespace/kube-storage created
$ kubectl get namespaces
NAME           STATUS   AGE
default        Active   33m
kube-public    Active   33m
kube-storage   Active   4s
kube-system    Active   33m
~~~~
1. Clone [Gluster-Kubernetes](https://github.com/gluster/gluster-kubernetes.git)
2. Change all references to heketi/heketi:dev with the image you've built
3. Change all references to the centos image with the gluster-fedora version
4. Update configs and topology.json
4. Deploy!

#### Hyperconverged Master
You also need to update `kube-templates/glusterfs-daemonset.yaml`  to add a toleration for running on the master. Update the spec to include:
~~~~
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule

~~~~

#### Topology
You'll need to describe your node topology

This file is a litle wierd because it has names and IPs, you need both.

check `src/topology.json` for an example. Please make sure the data volumes are blank, or else Heketi will complain. You can adjust the node configuration in the topology file to tell Heketi to wipe volumes like so:

~~~~
          "devices": [
       		  {"name":"/dev/loop0",
		         "destroydata": true}
          ]
~~~~

Next, you're ready to deploy!

~~~~
pi@raspberrypi-node0:~ $ git clone https://github.com/gluster/gluster-kubernetes.git
Cloning into 'gluster-kubernetes'...
...
cd deploy

find ./ -type f -exec \
    sed -i 's/heketi\/heketi:dev/localhost:5000\/heketi/g' {} +

find ./ -type f -exec \
    sed -i 's/gluster\/gluster-centos:latest/localhost:5000\/gluster-fedora/g' {} +

$ /gk-deploy -g --no-object -n kube-storage
~~~~

This will take some time, but if all goes well, you should now see your storage cluster up!

### Create a storage class
The output shold show your api endpoint, go ahead and apply a storage class using it e.g. 
~~~~
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: glusterfs-storage
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://10.36.0.2:8080"
~~~~

## Trying it all out...
You can test with a simple redis deployment in `eample/redis.yaml` it assumes you've created a storage class called `glusterfs-storage` as above

~~~~
kubectl apply -f redis.yaml -n kube-public
persistentvolumeclaim/redis-pv-claim created
service/redis created
deployment.apps/redis created
~~~~
Now, get the port:
~~~~
kubectl get svc redis -n kube-public
NAME      TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
redis     NodePort   10.98.3.164   <none>        6379:32686/TCP   4s
~~~~
Try it out
~~~~
$ redis-cli -h raspberrypi-node1 -p 32686
raspberrypi-node1:32686> get foo
(nil)
raspberrypi-node1:32686> set foo bar
OK
raspberrypi-node1:32686> get foo
"bar"
~~~~

