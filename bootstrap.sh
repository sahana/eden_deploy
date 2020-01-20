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

  roles:
    - swap
    - ansible
    - common
    - nginx
    - uwsgi
    - postgresql
    - final
EOF

echo "Now running ansible-playbook"

# HOME=/root required due to https://github.com/ansible/ansible/issues/21562
HOME=/root /usr/local/bin/ansible-playbook -i inventory deploy.yml