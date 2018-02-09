#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update
sudo apt-get update

# Install git
sudo apt-get install git-core

# Install ansible dependencies
sudo apt-get install python-pip python-dev git -y
sudo pip install PyYAML jinja2 paramiko

# Install Ansible
sudo pip install ansible

# Clone Ansible Playbooks
git clone https://github.com/gnarula/eden_playbook

# Run the install
cd eden_playbook

bash bootstrap_coapp.sh
