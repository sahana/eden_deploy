#!/bin/bash

pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`

# Which OS are we running?
read -d . DEBIAN < /etc/debian_version

# Install ansible dependencies
if [ $DEBIAN == '10' ]; then
    update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
    update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
    apt-get remove python3-jinja2 python3-yaml -qy
    apt-get install python-pip python3-pip python3-dev -qy
else
    apt-get install python-pip python-dev -qy
fi

pip install PyYAML jinja2 paramiko -q

# Install Ansible
pip install ansible -q

# Build Playbook
cat << EOF > "deploy_coapp.yml"
---
- hosts: localhost
  connection: local
  become_method: sudo
  become_user: root

  vars:
    sitename: '$pubDNS' # usually hostname.domain
    appname: eden

  roles:
    - swap
    - ansible
    - coapp
EOF

echo "Now running ansible-playbook"

# HOME=/root required due to https://github.com/ansible/ansible/issues/21562
HOME=/root /usr/local/bin/ansible-playbook -i inventory deploy_coapp.yml