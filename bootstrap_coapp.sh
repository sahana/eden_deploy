#!/bin/bash

# Which OS are we running?
read -d . DEBIAN < /etc/debian_version
echo running on Debian version $DEBIAN

# Are we running on Amazon EC2?
# https://serverfault.com/questions/462903/how-to-know-if-a-machine-is-an-ec2-instance
# This first, simple check will work for many older instance types.
if [ -f /sys/hypervisor/uuid ]; then
  # File should be readable by non-root users.
  if [ `head -c 3 /sys/hypervisor/uuid` == "ec2" ]; then
    echo running on EC2
    pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`
  else
    echo not running on EC2
    read -d . pubDNS < /etc/hostname
  fi

# This check will work on newer m5/c5 instances, but only if you have root!
elif [ -r /sys/devices/virtual/dmi/id/product_uuid ]; then
  # If the file exists AND is readable by us, we can rely on it.
  if [ `head -c 3 /sys/devices/virtual/dmi/id/product_uuid` == "ec2" ]; then
    echo running on EC2
    pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`
  else
    echo not running on EC2
    read -d . pubDNS < /etc/hostname
  fi

else
  # Fallback check of http://169.254.169.254/. If we wanted to be REALLY
  # authoritative, we could follow Amazon's suggestions for cryptographically
  # verifying their signature, see here:
  #    https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
  # but this is almost certainly overkill for this purpose (and the above
  # checks of "EC2" prefixes have a higher false positive potential, anyway).
  apt-get install -qy curl
  if $(curl -s -m 1 http://169.254.169.254/latest/dynamic/instance-identity/document | grep -q availabilityZone) ; then
    echo running on EC2
    pubDNS=`wget --quiet -O - http://169.254.169.254/latest/meta-data/public-hostname`
  else
    echo not running on EC2
    read -d . pubDNS < /etc/hostname
  fi

fi
echo using hostname $pubDNS

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