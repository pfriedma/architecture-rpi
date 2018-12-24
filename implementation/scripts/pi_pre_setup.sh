#!/bin/bash
# This script sets up the initial stuff on the raspberri pi to get you goingheadless (networking, ssh, etc)

# command to deal with unmounting the filesystem
# linux: umount
# osx: diskutil unmount
# windows: ???

UMNTCMD="diskutil unmount"

# Location where the SD card's /boot is mounted (usually /Volumes/boot on a mac)
BOOTPATH=/Volumes/boot

# Wifi ESSID and Password
WIFI_ESSID="your_ssid"
WIFI_PSK="foobar"

# If you want to use PXEBoot later (recommended for dynamic clustering) you need to do this step manually, put the card in the rpi, boot it, shut it down, then remove the line
#cd $BOOTPATH
#echo program_usb_boot_mode=1 >> config.txt 

cat > wpa_supplicant.conf <<- EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
     ssid="$WIFI_ESSID"
     psk="$WIFI_PSK"
}
EOF

# Set up SSH on boot...
touch ssh

# disk caching...
sync && sync && sync
$UMNTCMD $BOOTPATH 
