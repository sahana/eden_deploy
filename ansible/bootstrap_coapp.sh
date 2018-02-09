#!/bin/bash

pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`

cat << EOF > inventory
127.0.0.1
EOF

cat << EOF > "deploy_coapp.yml"
---
- hosts: 127.0.0.1
  connection: local
  remote_user: admin

  vars:
    sitename: '$pubDNS' # usually hostname.domain

  roles:
   - coapp
EOF

echo "Now running ansible-playbook"

/usr/local/bin/ansible-playbook -i inventory deploy_coapp.yml