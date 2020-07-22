#!/bin/bash

set -e
trap 'echo "Finished with exit code $?"' EXIT

echo "[ KEG CLI ] Running Keg-Boot Service setup..." >&2
echo "" >&2

if [[ $EUID -ne 0 ]]; then
   echo "[ KEG CLI ] Setup script must be run as root, or user with root privileges!" >&2
   exit 1
fi

# Make the script executable
sudo chmod +x /home/ubuntu/keg/keg-deploy/aws/keg-boot.sh

# Put the service file at /etc/systemd/system folder
sudo cp /home/ubuntu/keg/keg-deploy/aws/keg-boot.service /etc/systemd/system/keg-boot.service

# Ensure the permissions are correct
sudo chmod 0644 /etc/systemd/system/keg-boot.service

# After adding this file, restart the daemon
sudo systemctl daemon-reload

# Enable the docker.service
sudo systemctl start docker
sudo systemctl enable docker

# Enable the keg-boot.service
sudo systemctl enable keg-boot.service

echo "" >&2
echo "[ KEG CLI ] Keg-Boot Service setup complete!" >&2