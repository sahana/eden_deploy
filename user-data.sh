#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update
apt-get update

# Install git
apt-get install git -y

# Install ansible dependencies
apt-get install python-pip python-dev -y
pip install PyYAML jinja2 paramiko

# Install Ansible
pip install ansible

# Clone Ansible Playbooks
git clone https://github.com/sahana/eden_deploy

# Run the install
cd eden_deploy

#bash bootstrap.sh template hostname.domain sender@domain
# or
bash bootstrap_coapp.sh
