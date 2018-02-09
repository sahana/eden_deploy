#!/bin/bash
set -e
if [[ -z "$1" ]]; then
    echo >&2 "Instance needs to be specified: prod or test or demo"
    exit 1
elif [[ ! -d "/home/$1" ]]; then
    echo >&2 "$1 is not a valid instance!"
    exit 1
fi
INSTANCE=$1
#/etc/init.d/uwsgi-$INSTANCE stop
cd /home/$INSTANCE/applications/eden
rm -rf databases/*
rm -f errors/*
rm -f sessions/*
rm -rf uploads/*
echo >&2 "Dropping database: $DATABASE"
set +e
if [[ "$1" = "test" ]]; then
    cp -pr /home/prod/applications/eden/databases/* /home/$INSTANCE/applications/eden/databases/
    cd /home/$INSTANCE/applications/eden/databases
    for i in *.table; do mv "$i" "${i/PROD_TABLE_STRING/TEST_TABLE_STRING}"; done
else
    echo >&2 "Starting DB actions with eden"
    cd /home/$INSTANCE/applications/eden
    sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
    sed -i "s/settings.base.prepopulate = 0/#settings.base.prepopulate = 0/g" models/000_config.py
    rm -rf compiled
    cd /home/$INSTANCE
    sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
    cd /home/$INSTANCE/applications/eden
    sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
    sed -i "s/#settings.base.prepopulate = 0/settings.base.prepopulate = 0/g" models/000_config.py
fi
echo >&2 "Compiling..."
cd /home/$INSTANCE
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
#/etc/init.d/uwsgi-$INSTANCE start
