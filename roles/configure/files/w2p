#!/bin/bash
set -e
if [[ -z "$1" ]]; then
    echo >&2 "Instance needs to be specified: prod or test"
    exit 1
elif [[ ! -d "/home/$1" ]]; then
    echo >&2 "$1 is not a valid instance!"
    exit 1
fi
INSTANCE=$1
cd /home/$INSTANCE
python web2py.py -S eden -M