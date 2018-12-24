#!/bin/bash
# This script creates a loopback image and exposes it as /dev/loop0 for gluster. Modify as needed for multiple images/devices.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

IMAGE_SIZE="15G"
IMAGE_LOCATION="/var/gluster.img"
LOOPBACK_DEVICE="/dev/loop0"
LOOPBACK_SERVICE_FILE="loopback"
SYSTEMD_DIR="/etc/systemd/system"



echo "creating a file of size $IMAGE_SIZE at $IMAGE_LOCATION"
sudo fallocate -l $IMAGE_SIZE $IMAGE_LOCATION

echo "Creating loopback service in $SYSTEMD_DIR"
cat > $SYSTEMD_DIR/$LOOPBACK_SERVICE_FILE.service <<-EOF
[Unit]
Description=Activate loop device
DefaultDependencies=no
After=systemd-udev-settle.service
Before=lvm2-activation-early.service
Wants=systemd-udev-settle.service

[Service]
ExecStart=/sbin/losetup $LOOPBACK_DEVICE $IMAGE_LOCATION
Type=oneshot

[Install]
WantedBy=local-fs.target
EOF
echo "Calling systemctl daemon-reload and running the loopback service..."
sudo systemctl daemon-reload
sudo systemctl enable loopback.service
sudo systemctl start loopback.service
echo "Done!"



