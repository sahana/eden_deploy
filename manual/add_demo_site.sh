#!/bin/bash

# Script to add a Demo site to a server configured with CherokeePostGIS
# - assumes that a Test site has already been added

echo -e "What FQDN will be used to access the demo site? : \c "
read sitename

ln -sf /home/web2py /home/prod
ln -sf /home/prod ~

cd /home
git clone --recursive git://github.com/web2py/web2py.git demo
cd demo
# 2.14.6
git reset --hard cda35fd
git submodule update --init --recursive
ln -s /home/demo ~
cat << EOF > "/home/demo/routes.py"
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
cd /home/demo/applications
# @ToDo: Stable branch
git clone git://github.com/flavour/eden.git
# Fix permissions
chown web2py /home/demo
chown web2py /home/demo/applications/admin/cache
chown web2py /home/demo/applications/admin/cron
chown web2py /home/demo/applications/admin/databases
chown web2py /home/demo/applications/admin/errors
chown web2py /home/demo/applications/admin/sessions
chown web2py /home/demo/applications/eden
chown web2py /home/demo/applications/eden/cache
chown web2py /home/demo/applications/eden/cron
mkdir -p /home/demo/applications/eden/databases
chown web2py /home/demo/applications/eden/databases
chown web2py /home/demo/applications/eden/errors
chown web2py /home/demo/applications/eden/models
chown web2py /home/demo/applications/eden/sessions
chown web2py /home/demo/applications/eden/static/img/markers
mkdir -p /home/demo/applications/eden/static/cache/chart
chown web2py -R /home/demo/applications/eden/static/cache
mkdir -p /home/demo/applications/eden/uploads/gis_cache
mkdir -p /home/demo/applications/eden/uploads/images
mkdir -p /home/demo/applications/eden/uploads/tracks
chown web2py /home/demo/applications/eden/uploads
chown web2py /home/demo/applications/eden/uploads/gis_cache
chown web2py /home/demo/applications/eden/uploads/images
chown web2py /home/demo/applications/eden/uploads/tracks
ln -s /home/demo/applications/eden /home/demo

# Configure Matplotlib
mkdir /home/demo/.matplotlib
chown web2py /home/demo/.matplotlib
cp /home/demo/handlers/wsgihandler.py /home/demo
echo "os.environ['MPLCONFIGDIR'] = '/home/demo/.matplotlib'" >> /home/demo/wsgihandler.py

# Configure
cp /home/web2py/applications/eden/models/000_config.py /home/demo/applications/eden/models/000_config.py
sed -i "s|settings.base.public_url = .*\"|settings.base.public_url = \"http://$sitename\"|" /home/demo/applications/eden/models/000_config.py
sed -i "s|settings.mail.sender = .*\"|#settings.mail.sender = disabled|" /home/demo/applications/eden/models/000_config.py
sed -i "s|#settings.database.database = \"sahana\"|settings.database.database = \"sahana-demo\"|" /home/demo/applications/eden/models/000_config.py

# Configure uwsgi

## Add Scheduler config

cat << EOF > "/home/demo/run_scheduler.py"
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


cat << EOF > "/home/demo/uwsgi.ini"
[uwsgi]
uid = web2py
gid = web2py
chdir = /home/demo/
module = wsgihandler
mule = run_scheduler.py
workers = 2
cheap = true
idle = 1000
harakiri = 1000
pidfile = /tmp/uwsgi-demo.pid
daemonize = /var/log/uwsgi/demo.log
socket = 127.0.0.1:59027
master = true
EOF

touch /tmp/uwsgi-demo.pid
chown web2py: /tmp/uwsgi-demo.pid

# Init script for uwsgi

cat << EOF > "/etc/init.d/uwsgi-demo"
#! /bin/bash
# /etc/init.d/uwsgi-demo
#

daemon=/usr/local/bin/uwsgi
pid=/tmp/uwsgi-demo.pid
args="/home/demo/uwsgi.ini"

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
        echo "Usage: /etc/init.d/uwsgi-demo {start|stop|restart|reload}"
        exit 1
    ;;
esac
exit 0
EOF

chmod a+x /etc/init.d/uwsgi-demo
# If you want the service enabling at boot:
#update-rc.d uwsgi-demo defaults
/etc/init.d/uwsgi-demo start

cat << EOF > "/tmp/update_cherokee.py"
vserver = """
vserver!50!collector!enabled = 1
vserver!50!directory_index = index.html
vserver!50!document_root = /var/www
vserver!50!error_handler = error_redir
vserver!50!error_handler!503!show = 0
vserver!50!error_handler!503!url = /maintenance.html
vserver!50!error_writer!filename = /var/log/cherokee/cherokee.error
vserver!50!error_writer!type = file
vserver!50!logger = combined
vserver!50!logger!access!buffsize = 16384
vserver!50!logger!access!filename = /var/log/cherokee/cherokee.access
vserver!50!logger!access!type = file
vserver!50!match = wildcard
vserver!50!match!domain!1 = $sitename
vserver!50!match!nick = 0
vserver!50!nick = Demo
vserver!50!rule!700!expiration = epoch
vserver!50!rule!700!expiration!caching = public
vserver!50!rule!700!expiration!caching!must-revalidate = 1
vserver!50!rule!700!expiration!caching!no-store = 0
vserver!50!rule!700!expiration!caching!no-transform = 0
vserver!50!rule!700!expiration!caching!proxy-revalidate = 1
vserver!50!rule!700!handler = common
vserver!50!rule!700!handler!allow_dirlist = 0
vserver!50!rule!700!handler!allow_pathinfo = 0
vserver!50!rule!700!match = fullpath
vserver!50!rule!700!match!fullpath!1 = /maintenance.html
vserver!50!rule!500!document_root = /home/demo/applications/eden/static
vserver!50!rule!500!encoder!deflate = allow
vserver!50!rule!500!encoder!gzip = allow
vserver!50!rule!500!expiration = time
vserver!50!rule!500!expiration!time = 7d
vserver!50!rule!500!handler = file
vserver!50!rule!500!match = fullpath
vserver!50!rule!500!match!fullpath!1 = /favicon.ico
vserver!50!rule!500!match!fullpath!2 = /robots.txt
vserver!50!rule!500!match!fullpath!3 = /crossdomain.xml
vserver!50!rule!400!document_root = /home/demo/applications/eden/static/img
vserver!50!rule!400!encoder!deflate = forbid
vserver!50!rule!400!encoder!gzip = forbid
vserver!50!rule!400!expiration = time
vserver!50!rule!400!expiration!caching = public
vserver!50!rule!400!expiration!caching!must-revalidate = 0
vserver!50!rule!400!expiration!caching!no-store = 0
vserver!50!rule!400!expiration!caching!no-transform = 0
vserver!50!rule!400!expiration!caching!proxy-revalidate = 0
vserver!50!rule!400!expiration!time = 7d
vserver!50!rule!400!handler = file
vserver!50!rule!400!match = directory
vserver!50!rule!400!match!directory = /eden/static/img/
vserver!50!rule!400!match!final = 1
vserver!50!rule!300!document_root = /home/demo/applications/eden/static
vserver!50!rule!300!encoder!deflate = allow
vserver!50!rule!300!encoder!gzip = allow
vserver!50!rule!300!expiration = epoch
vserver!50!rule!300!expiration!caching = public
vserver!50!rule!300!expiration!caching!must-revalidate = 1
vserver!50!rule!300!expiration!caching!no-store = 0
vserver!50!rule!300!expiration!caching!no-transform = 0
vserver!50!rule!300!expiration!caching!proxy-revalidate = 1
vserver!50!rule!300!handler = file
vserver!50!rule!300!match = directory
vserver!50!rule!300!match!directory = /eden/static/
vserver!50!rule!300!match!final = 1
vserver!50!rule!200!encoder!deflate = allow
vserver!50!rule!200!encoder!gzip = allow
vserver!50!rule!200!handler = uwsgi
vserver!50!rule!200!handler!balancer = round_robin
vserver!50!rule!200!handler!balancer!source!10 = 3
vserver!50!rule!200!handler!check_file = 0
vserver!50!rule!200!handler!error_handler = 1
vserver!50!rule!200!handler!modifier1 = 0
vserver!50!rule!200!handler!modifier2 = 0
vserver!50!rule!200!handler!pass_req_headers = 1
vserver!50!rule!200!match = directory
vserver!50!rule!200!match!directory = /
vserver!50!rule!100!handler = common
vserver!50!rule!100!handler!iocache = 1
vserver!50!rule!100!match = default
"""

source = """
source!3!env_inherited = 1
source!3!group = web2py
source!3!host = 127.0.0.1:59027
source!3!interpreter = /usr/local/bin/uwsgi -s 127.0.0.1:59027 -x /home/demo/uwsgi.xml
source!3!nick = uWSGI 3
source!3!timeout = 1000
source!3!type = host
source!3!user = web2py
"""

File = open("/etc/cherokee/cherokee.conf", "r")
file = File.readlines()
File.close()
File = open("/etc/cherokee/cherokee.conf", "w")
for line in file:
    if "source!2!env_inherited" in line:
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
sed -i "s|prod or test|prod, demo or test|" /usr/local/bin/clean
sed -i "s|prod or test|prod, demo or test|" /usr/local/bin/compile
sed -i "s|prod or test|prod, demo or test|" /usr/local/bin/pull
sed -i "s|prod or test|prod, demo or test|" /usr/local/bin/w2p

# 1st time setup
clean demo

# END
