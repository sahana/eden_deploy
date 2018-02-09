#!/bin/bash

password=`date +%s | sha256sum | base64 | head -c 32 ; echo`
privDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/hostname | sed "s/.ec2.internal//"`
pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`
template="default"

cat << EOF > inventory
127.0.0.1
EOF

cat << EOF > "deploy.yml"
---
- hosts: 127.0.0.1
  connection: local
  sudo: yes

  vars:
    hostname: '$privDNS'
    password: '$password'
    domain: '$pubDNS'
    sitename: '$pubDNS' # usually hostname.domain
    template: '$template'

  roles:
    - common
    - cherokee
    - uwsgi
    - postgresql
    - configure
EOF

echo "Now running ansible-playbook"

/usr/local/bin/ansible-playbook -i inventory deploy.yml