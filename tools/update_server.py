#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Script to update the setup_ database with details of a newly-deployed Amazon EC2 instance
#
# Run as:
#   python web2py.py -S eden -M -R applications/eden/private/eden_deploy/tools/update_server.py -A server_id instance_id public_ip private_key

import sys

def main(argv):
    # Parse Arguments
    try:
        server_id = argv[0]
    except IndexError:
        print("No server_id supplied")
        sys.exit(2)
    try:
        instance_id = argv[1]
    except IndexError:
        print("No instance_id supplied")
        sys.exit(2)
    try:
        public_ip = argv[2]
    except IndexError:
        print("No public_ip supplied")
        sys.exit(2)
    try:
        private_key = argv[3] # Name of file in /tmp
    except IndexError:
        print("No private_key supplied")
        sys.exit(2)

    # Update Server record
    table = s3db.setup_server

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

    # Update AWS Server record with the Instance ID
    table = s3db.setup_aws_server
    db(table.server_id == server_id).update(instance_id = instance_id)

    db.commit()

if __name__ == "__main__":

    sys.exit(main(sys.argv[1:]))
