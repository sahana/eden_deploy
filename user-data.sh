#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Which OS are we running?
read -d . DEBIAN < /etc/debian_version

# Update
apt-get update

# Install git
apt-get install git -y

# Install ansible dependencies

if [ $DEBIAN == '10' ]; then
    update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
    update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
    apt-get install python-pip python3-pip python3-dev -y
else
    apt-get install python-pip python-dev -y
fi

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
