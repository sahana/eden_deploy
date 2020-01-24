#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Script to update the setup_ database with details of a newly-deployed Amazon EC2 instance
#
# Run as:
#   python web2py.py -S eden -M -R applications/eden/private/eden_deploy/tools/update_server.py -A server_id instance_id public_ip private_key
#
# NB A generic way to find out the Public IP is https://docs.ansible.com/ansible/latest/modules/ipify_facts_module.html
#

import sys

# Parse Arguments
# argv[0] is the script name
try:
    server_id = sys.argv[1]
except IndexError:
    print("No server_id supplied")
    sys.exit(2)
#else:
#    print("server_id: %s" % server_id)
try:
    instance_id = sys.argv[2]
except IndexError:
    print("No instance_id supplied")
    sys.exit(2)
#else:
#    print("instance_id: %s" % instance_id)
try:
    public_ip = sys.argv[3]
except IndexError:
    print("No public_ip supplied")
    sys.exit(2)
#else:
#    print("public_ip: %s" % public_ip)
try:
    private_key = sys.argv[4] # Name of file in /tmp
except IndexError:
    print("No private_key supplied")
    sys.exit(2)
#else:
#    print("private_key: %s" % private_key)

# Update Server record
table = s3db.setup_server
private_key_path = os.path.join("/", "tmp", private_key)
field = table.private_key
newfilename = None
with open(private_key_path, "r") as private_key_file:
    newfilename = field.store(private_key_file,
                              "%s.pem" % private_key,
                              field.uploadfolder)
db(table.id == server_id).update(host_ip = public_ip,
                                 private_key = newfilename,
                                 )

# Update AWS Server record with the Instance ID
atable = s3db.setup_aws_server
db(atable.server_id == server_id).update(instance_id = instance_id)

db.commit()