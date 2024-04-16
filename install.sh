#!/bin/bash

echo Installing the immich backup tool...
# Moove the script to the correct location and set the permissions
sudo cp auto_backup_immich.sh /usr/sbin/backup
sudo chmod 550 /usr/sbin/backup
sudo chown root:root /usr/sbin/backup

echo Installing dependecies...
# Install jq ( needed for the parsing of the external json configuration )
sudo apt install jq

# Create the config directory
mkdir /etc/backup/
# Move the config file to the correct location
read -p "Please modify your configuration in the config.conf file and press enter: "
sudo cp config.json /etc/backup/config.json 


echo The backup can now be triggered by executing the backup command as an administrator