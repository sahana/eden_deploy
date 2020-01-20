#!/bin/bash

pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`

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