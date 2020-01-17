#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Run as:
#   python web2py.py -S eden -M -R applications/eden/private/eden_deploy/tools/update_server.py -A server_id instance_id public_ip private_key

def main(argv):
    # Parse Arguments
    server_id = argv[0]
    instance_id = argv[1]
    public_ip = argv[2]
    private_key = argv[3]

    s3db = current.s3db

    # Update Server record with the IP Address
    table = s3db.setup_server
    db(table.id == server_id).update(host_ip = public_ip)

    # Upload SSH Private Key to the Server record
    private_key_path = os.path.join("/", "tmp", private_key)
    with openf(private_key_path, "r") as private_key_file:
        field = table.private_key
        field.store(private_key_file,
                    "%s.pem" % private_key,
                    field.uploadfolder)

    # Update AWS Server record with the Instance ID
    table = s3db.setup_aws_server
    db(table.server_id == server_id).update(instance_id = instance_id)
