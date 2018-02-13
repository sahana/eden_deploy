#!/bin/bash

# Script to add a Test site to a server configured with CherokeePostGIS

echo -e "What FQDN will be used to access the test site? : \c "
read sitename

ln -sf /home/web2py /home/prod
ln -sf /home/prod ~

cd /home
git clone --recursive git://github.com/web2py/web2py.git test
cd test
# 2.14.6
git reset --hard cda35fd
git submodule update --init --recursive
ln -s /home/test ~
cat << EOF > "/home/test/routes.py"
#!/usr/bin/python
default_application = 'eden'
default_controller = 'default'
default_function = 'index'
routes_onerror = [
        ('eden/400', '!'),
        ('eden/401', '!'),
        ('eden/509', '!'),
        ('eden/*', '/eden/errors/index'),
        ('*/*', '/eden/errors/index'),
    ]
EOF


##############
# Sahana Eden
##############
# Install Sahana Eden
cd /home/test/applications
# @ToDo: Stable branch
git clone git://github.com/flavour/eden.git
# Fix permissions
chown web2py /home/test
chown web2py /home/test/applications/admin/cache
chown web2py /home/test/applications/admin/cron
chown web2py /home/test/applications/admin/databases
chown web2py /home/test/applications/admin/errors
chown web2py /home/test/applications/admin/sessions
chown web2py /home/test/applications/eden
chown web2py /home/test/applications/eden/cache
chown web2py /home/test/applications/eden/cron
mkdir -p /home/test/applications/eden/databases
chown web2py /home/test/applications/eden/databases
chown web2py /home/test/applications/eden/errors
chown web2py /home/test/applications/eden/models
chown web2py /home/test/applications/eden/sessions
chown web2py /home/test/applications/eden/static/img/markers
mkdir -p /home/test/applications/eden/static/cache/chart
chown web2py -R /home/test/applications/eden/static/cache
mkdir -p /home/test/applications/eden/uploads/gis_cache
mkdir -p /home/test/applications/eden/uploads/images
mkdir -p /home/test/applications/eden/uploads/tracks
chown web2py /home/test/applications/eden/uploads
chown web2py /home/test/applications/eden/uploads/gis_cache
chown web2py /home/test/applications/eden/uploads/images
chown web2py /home/test/applications/eden/uploads/tracks
ln -s /home/test/applications/eden /home/test

# Configure Matplotlib
mkdir /home/test/.matplotlib
chown web2py /home/test/.matplotlib
cp /home/test/handlers/wsgihandler.py /home/test
echo "os.environ['MPLCONFIGDIR'] = '/home/test/.matplotlib'" >> /home/test/wsgihandler.py

# Configure
cp /home/web2py/applications/eden/models/000_config.py /home/test/applications/eden/models/000_config.py
sed -i "s|settings.base.public_url = .*\"|settings.base.public_url = \"http://$sitename\"|" /home/test/applications/eden/models/000_config.py
sed -i "s|settings.mail.sender = .*\"|#settings.mail.sender = disabled|" /home/test/applications/eden/models/000_config.py
sed -i "s|#settings.database.database = \"sahana\"|settings.database.database = \"sahana-test\"|" /home/test/applications/eden/models/000_config.py

# Configure uwsgi

## Add Scheduler config

cat << EOF > "/home/test/run_scheduler.py"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys

if '__file__' in globals():
    path = os.path.dirname(os.path.abspath(__file__))
    os.chdir(path)
else:
    path = os.getcwd() # Seems necessary for py2exe

sys.path = [path]+[p for p in sys.path if not p==path]

# import gluon.import_all ##### This should be uncommented for py2exe.py
import gluon.widget
from gluon.shell import run

# Start Web2py Scheduler -- Note the app name is hardcoded!
if __name__ == '__main__':
    run('eden',True,True,None,False,"from gluon import current; current._scheduler.loop()")
EOF


cat << EOF > "/home/test/uwsgi.ini"
[uwsgi]
uid = web2py
gid = web2py
chdir = /home/test/
module = wsgihandler
mule = run_scheduler.py
workers = 2
cheap = true
idle = 1000
harakiri = 1000
pidfile = /tmp/uwsgi-test.pid
daemonize = /var/log/uwsgi/test.log
socket = 127.0.0.1:59026
master = true
EOF

touch /tmp/uwsgi-test.pid
chown web2py: /tmp/uwsgi-test.pid

# Init script for uwsgi

cat << EOF > "/etc/init.d/uwsgi-test"
#! /bin/bash
# /etc/init.d/uwsgi-test
#

daemon=/usr/local/bin/uwsgi
pid=/tmp/uwsgi-test.pid
args="/home/test/uwsgi.ini"

# Carry out specific functions when asked to by the system
case "\$1" in
    start)
        echo "Starting uwsgi"
        start-stop-daemon -p \$pid --start --exec \$daemon -- \$args
        ;;
    stop)
        echo "Stopping script uwsgi"
        start-stop-daemon --signal INT -p \$pid --stop \$daemon -- \$args
        ;;
    restart)
        \$0 stop
        sleep 1
        \$0 start
        ;;
    reload)
        echo "Reloading conf"
        kill -HUP \`cat \$pid\`
        ;;
    *)
        echo "Usage: /etc/init.d/uwsgi-test {start|stop|restart|reload}"
        exit 1
    ;;
esac
exit 0
EOF

chmod a+x /etc/init.d/uwsgi-test
# If you want the service enabling at boot:
#update-rc.d uwsgi-test defaults
/etc/init.d/uwsgi-test start

cat << EOF > "/tmp/update_cherokee.py"
vserver = """
vserver!40!collector!enabled = 1
vserver!40!directory_index = index.html
vserver!40!document_root = /var/www
vserver!40!error_handler = error_redir
vserver!40!error_handler!503!show = 0
vserver!40!error_handler!503!url = /maintenance.html
vserver!40!error_writer!filename = /var/log/cherokee/cherokee.error
vserver!40!error_writer!type = file
vserver!40!logger = combined
vserver!40!logger!access!buffsize = 16384
vserver!40!logger!access!filename = /var/log/cherokee/cherokee.access
vserver!40!logger!access!type = file
vserver!40!match = wildcard
vserver!40!match!domain!1 = $sitename
vserver!40!match!nick = 0
vserver!40!nick = Test
vserver!40!rule!700!expiration = epoch
vserver!40!rule!700!expiration!caching = public
vserver!40!rule!700!expiration!caching!must-revalidate = 1
vserver!40!rule!700!expiration!caching!no-store = 0
vserver!40!rule!700!expiration!caching!no-transform = 0
vserver!40!rule!700!expiration!caching!proxy-revalidate = 1
vserver!40!rule!700!handler = common
vserver!40!rule!700!handler!allow_dirlist = 0
vserver!40!rule!700!handler!allow_pathinfo = 0
vserver!40!rule!700!match = fullpath
vserver!40!rule!700!match!fullpath!1 = /maintenance.html
vserver!40!rule!500!document_root = /home/test/applications/eden/static
vserver!40!rule!500!encoder!deflate = allow
vserver!40!rule!500!encoder!gzip = allow
vserver!40!rule!500!expiration = time
vserver!40!rule!500!expiration!time = 7d
vserver!40!rule!500!handler = file
vserver!40!rule!500!match = fullpath
vserver!40!rule!500!match!fullpath!1 = /favicon.ico
vserver!40!rule!500!match!fullpath!2 = /robots.txt
vserver!40!rule!500!match!fullpath!3 = /crossdomain.xml
vserver!40!rule!400!document_root = /home/test/applications/eden/static/img
vserver!40!rule!400!encoder!deflate = forbid
vserver!40!rule!400!encoder!gzip = forbid
vserver!40!rule!400!expiration = time
vserver!40!rule!400!expiration!caching = public
vserver!40!rule!400!expiration!caching!must-revalidate = 0
vserver!40!rule!400!expiration!caching!no-store = 0
vserver!40!rule!400!expiration!caching!no-transform = 0
vserver!40!rule!400!expiration!caching!proxy-revalidate = 0
vserver!40!rule!400!expiration!time = 7d
vserver!40!rule!400!handler = file
vserver!40!rule!400!match = directory
vserver!40!rule!400!match!directory = /eden/static/img/
vserver!40!rule!400!match!final = 1
vserver!40!rule!300!document_root = /home/test/applications/eden/static
vserver!40!rule!300!encoder!deflate = allow
vserver!40!rule!300!encoder!gzip = allow
vserver!40!rule!300!expiration = epoch
vserver!40!rule!300!expiration!caching = public
vserver!40!rule!300!expiration!caching!must-revalidate = 1
vserver!40!rule!300!expiration!caching!no-store = 0
vserver!40!rule!300!expiration!caching!no-transform = 0
vserver!40!rule!300!expiration!caching!proxy-revalidate = 1
vserver!40!rule!300!handler = file
vserver!40!rule!300!match = directory
vserver!40!rule!300!match!directory = /eden/static/
vserver!40!rule!300!match!final = 1
vserver!40!rule!200!encoder!deflate = allow
vserver!40!rule!200!encoder!gzip = allow
vserver!40!rule!200!handler = uwsgi
vserver!40!rule!200!handler!balancer = round_robin
vserver!40!rule!200!handler!balancer!source!10 = 2
vserver!40!rule!200!handler!check_file = 0
vserver!40!rule!200!handler!error_handler = 1
vserver!40!rule!200!handler!modifier1 = 0
vserver!40!rule!200!handler!modifier2 = 0
vserver!40!rule!200!handler!pass_req_headers = 1
vserver!40!rule!200!match = directory
vserver!40!rule!200!match!directory = /
vserver!40!rule!100!handler = common
vserver!40!rule!100!handler!iocache = 1
vserver!40!rule!100!match = default
"""

source = """
source!2!env_inherited = 1
source!2!group = web2py
source!2!host = 127.0.0.1:59026
source!2!interpreter = /usr/local/bin/uwsgi -s 127.0.0.1:59026 -x /home/test/uwsgi.xml
source!2!nick = uWSGI 2
source!2!timeout = 1000
source!2!type = host
source!2!user = web2py
"""

File = open("/etc/cherokee/cherokee.conf", "r")
file = File.readlines()
File.close()
File = open("/etc/cherokee/cherokee.conf", "w")
for line in file:
    if "source!1!env_inherited" in line:
        File.write(vserver)
    elif "icons!directory" in line:
        File.write(source)
    File.write(line)
File.close()
EOF
python /tmp/update_cherokee.py

/etc/init.d/cherokee restart


#####################
# Management scripts
#####################
cat << EOF > "/usr/local/bin/compile"
#!/bin/bash
set -e
if [[ -z "\$1" ]]; then
    echo >&2 "Instance needs to be specified: prod or test"
    exit 1
elif [[ ! -d "/home/\$1" ]]; then
    echo >&2 "\$1 is not a valid instance!"
    exit 1
fi
INSTANCE=\$1
cd /home/\$INSTANCE
/etc/init.d/uwsgi-\$INSTANCE stop
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-\$INSTANCE start
EOF
chmod +x /usr/local/bin/compile

cat << EOF > "/usr/local/bin/pull"
#!/bin/bash
set -e
if [[ -z "\$1" ]]; then
    echo >&2 "Instance needs to be specified: prod or test"
    exit 1
elif [[ ! -d "/home/\$1" ]]; then
    echo >&2 "\$1 is not a valid instance!"
    exit 1
fi
INSTANCE=\$1
/etc/init.d/uwsgi-\$INSTANCE stop
cd /home/\$INSTANCE/applications/eden
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
git reset --hard HEAD
git pull
rm -rf compiled
cd /home/\$INSTANCE
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd /home/\$INSTANCE/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
cd /home/\$INSTANCE
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-\$INSTANCE start
EOF
chmod +x /usr/local/bin/pull

cat << EOF > "/usr/local/bin/clean"
#!/bin/bash
set -e
if [[ -z "\$1" ]]; then
    echo >&2 "Instance needs to be specified: prod or test"
    exit 1
elif [[ ! -d "/home/\$1" ]]; then
    echo >&2 "\$1 is not a valid instance!"
    exit 1
fi
INSTANCE=\$1
if [[ "\$1" = "prod" ]]; then
    echo "You selected: Production"
    echo -n "Are you absolutely sure? (yes/n):"
    read confirm
    if [ "\$confirm" != "yes" ]; then
        echo "Cancelled"; exit
    fi
    DATABASE="sahana"
else
    DATABASE="sahana-\$INSTANCE"
fi
echo >&2 "Cleaning instance: \$INSTANCE"
/etc/init.d/uwsgi-\$INSTANCE stop
cd /home/\$INSTANCE/applications/eden
rm -rf databases/*
rm -f errors/*
rm -rf sessions/*
rm -rf uploads/*
echo >&2 "Dropping database: \$DATABASE"
set +e
pkill -f "postgres: sahana \$DATABASE"
sudo -H -u postgres dropdb \$DATABASE
set -e
echo >&2 "Creating database: \$DATABASE"
su -c - postgres "createdb -O sahana -E UTF8 \$DATABASE -T template0"
if [[ "\$1" = "test" ]]; then
    echo >&2 "Refreshing database from Production: \$DATABASE"
    su -c - postgres "pg_dump -c sahana > /tmp/sahana.sql"
    su -c - postgres "psql -f /tmp/sahana.sql \$DATABASE"
    set +e
    cp -pr /home/prod/applications/eden/uploads/* /home/\$INSTANCE/applications/eden/uploads/
    set -e
    cp -pr /home/prod/applications/eden/databases/* /home/\$INSTANCE/applications/eden/databases/
    cd /home/\$INSTANCE/applications/eden/databases
    for i in *.table; do mv "\$i" "\${i/PROD_TABLE_STRING/TEST_TABLE_STRING}"; done
else
    echo >&2 "Migrating/Populating database: \$DATABASE"
    #su -c - postgres "createlang plpgsql -d \$DATABASE"
    #su -c - postgres "psql -q -d \$DATABASE -f /usr/share/postgresql/9.6/extension/postgis--2.3.0.sql"
    su -c - postgres "psql -q -d \$DATABASE -c 'CREATE EXTENSION postgis;'"
    su -c - postgres "psql -q -d \$DATABASE -c 'grant all on geometry_columns to sahana;'"
    su -c - postgres "psql -q -d \$DATABASE -c 'grant all on spatial_ref_sys to sahana;'"
    echo >&2 "Starting DB actions with eden"
    cd /home/\$INSTANCE/applications/eden
    sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
    sed -i "s/settings.base.prepopulate = 0/#settings.base.prepopulate = 0/g" models/000_config.py
    rm -rf compiled
    cd /home/\$INSTANCE
    sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
    cd /home/\$INSTANCE/applications/eden
    sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
    sed -i "s/#settings.base.prepopulate = 0/settings.base.prepopulate = 0/g" models/000_config.py
fi
echo >&2 "Compiling..."
cd /home/\$INSTANCE
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-\$INSTANCE start
# Post-pop
#if [[ "\$1" = "test"]]; then
#    echo >&2 "pass"
#else
#    cd /home/\$INSTANCE
#    sudo -H -u web2py python web2py.py -S eden -M -R /home/data/import.py
#fi
EOF
chmod +x /usr/local/bin/clean

cat << EOF > "/tmp/update_clean.py"
import hashlib
db_string = settings.get_database_string()[1]
prod_table_string = hashlib.md5(db_string).hexdigest()
settings._db_params = None
settings.database.database = "sahana-test"
db_string = settings.get_database_string()[1]
test_table_string = hashlib.md5(db_string).hexdigest()
File = open("/usr/local/bin/clean", "r")
file = File.readlines()
File.close()
File = open("/usr/local/bin/clean", "w")
for line in file:
    if "TABLE_STRING" in line:
        line = line.replace("PROD_TABLE_STRING", prod_table_string).replace("TEST_TABLE_STRING", test_table_string)
    File.write(line)
File.close()
EOF
cd /home/web2py
python web2py.py -S eden -M -R /tmp/update_clean.py

cat << EOF > "/usr/local/bin/w2p"
#!/bin/bash
set -e
if [[ -z "\$1" ]]; then
    echo >&2 "Instance needs to be specified: prod or test"
    exit 1
elif [[ ! -d "/home/\$1" ]]; then
    echo >&2 "\$1 is not a valid instance!"
    exit 1
fi
INSTANCE=\$1
cd /home/\$INSTANCE
python web2py.py -S eden -M
EOF
chmod +x /usr/local/bin/w2p

# 1st time setup
clean test

# END
