#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Script to update the setup_ database with details of a newly-deployed Amazon EC2 instance
#
# Run as:
#   python web2py.py -S eden -M -R applications/eden/private/eden_deploy/tools/update_server.py -A server_id instance_id public_ip private_key

def main(argv):
    # Parse Arguments
    server_id = argv[0]
    instance_id = argv[1]
    public_ip = argv[2]
    private_key = argv[3] # Name of file in /tmp

    # Debug
    log_path = os.path.join("/", "tmp", "update_server.log")
    with open(log_path, "w") as log_file:
        log_file.write("server_id: %s\ninstance_id: %s\nspublic_ip: %s\nprivate_key: %s\n" % (server_id, instance_id, public_ip, private_key))

    # Update Server record
    table = s3db.setup_server

    if private_key is not None:
        # Upload SSH Private Key to the Server record
        private_key_path = os.path.join("/", "tmp", private_key)
        field = table.private_key
        with open(private_key_path, "r") as private_key_file:
            newfilename = field.store(private_key_file,
                                      "%s.pem" % private_key,
                                      field.uploadfolder)
        db(table.id == server_id).update(host_ip = public_ip,
                                         private_key = newfilename,
                                         )
    else:
        db(table.id == server_id).update(host_ip = public_ip)

    # Update AWS Server record with the Instance ID
    table = s3db.setup_aws_server
    db(table.server_id == server_id).update(instance_id = instance_id)

    db.commit()
