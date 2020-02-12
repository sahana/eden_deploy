#!/bin/bash
# Copy user-data log into main system log
# NB This won't catch any final timeout in cloud-init
# see that with systemctl status cloud-final.service
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update
apt-get update

# Install git
apt-get install git -qy

# Clone Ansible Playbooks
git clone https://github.com/sahana/eden_deploy

# Run the install
cd eden_deploy

#bash bootstrap.sh template hostname.domain sender@domain
# or
bash bootstrap_coapp.sh
