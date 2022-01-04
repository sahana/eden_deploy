#!/bin/bash

password=`date +%s | sha256sum | base64 | head -c 32 ; echo`

if [ -z "$1" ]; then
    template="default"
else
    template="$1"
fi

if [ -z "$2" ]; then
    pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`
    privDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/hostname | sed "s/.compute.internal//"`
else
    # hostname.domain
    pubDNS="$2"
    privDNS=`echo "$2" | sed "s/\..*$//"`
fi

if [ -z "$3" ]; then
    sender=""
else
    sender="$3"
fi

# Which OS are we running?
read -d . DEBIAN < /etc/debian_version

# Install ansible dependencies
if [ $DEBIAN == '11' ]; then
    update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
    apt-get remove python3-jinja2 python3-yaml -qy
    apt-get install python3-pip python3-dev -qy
elif [ $DEBIAN == '10' ]; then
    update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
    update-alternatives --install /usr/bin/python python /usr/bin/python3.7 2
    apt-get remove python3-jinja2 python3-yaml -qy
    apt-get install python-pip python3-pip python3-dev -qy
else
    apt-get install python-pip python-dev -qy
fi

apt-get install -qy sudo

pip install PyYAML jinja2 paramiko -q

# Install Ansible
pip install ansible -q

# Build Playbook
cat << EOF > "deploy.yml"
---
- hosts: localhost
  connection: local
  become_method: sudo
  become_user: root

  vars:
    appname: 'eden'
    db_ip: '127.0.0.1'
    db_type: 'postgresql'
    hostname: '$privDNS'
    password: '$password'
    protocol: 'http'
    sitename: '$pubDNS'
    template: '$template'
    type: 'prod'
    start: True
    web_server: 'nginx'
    repo_url: 'https://github.com/sahana/eden-stable.git'

  roles:
    - swap
    - ansible
    - common
    - exim
    - postgresql
    - uwsgi
    - nginx
    - final
EOF

echo "Now running ansible-playbook"

# HOME=/root required due to https://github.com/ansible/ansible/issues/21562
HOME=/root /usr/local/bin/ansible-playbook -i inventory deploy.yml
