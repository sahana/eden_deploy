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
/etc/init.d/uwsgi-$INSTANCE stop
cd /home/$INSTANCE/applications/eden
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
git reset --hard HEAD
git pull
rm -rf compiled
cd /home/$INSTANCE
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd /home/$INSTANCE/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
cd /home/$INSTANCE
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-$INSTANCE start