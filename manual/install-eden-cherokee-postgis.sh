#!/bin/bash

# Script to turn a generic Debian Wheezy or Jessie box into an Eden server
# with Cherokee & PostgreSQL
# - tunes PostgreSQL for 512Mb RAM (e.g. Amazon Micro (free tier))
# - run pg1024 to tune for 1Gb RAM (e.g. Amazon Small or greater)

# Which OS are we running?
read -d . DEBIAN < /etc/debian_version

if [ $DEBIAN == '9' ]; then
    DEBIAN_NAME='stretch'
elif [ $DEBIAN == '8' ]; then
    DEBIAN_NAME='jessie'
else
    DEBIAN_NAME='wheezy'
fi

# Update system
apt-get update
apt-get -y upgrade
apt-get clean

# Install Admin Tools
apt-get -y install unzip psmisc mlocate telnet lrzsz vim rcconf htop sudo p7zip dos2unix curl
if [ $DEBIAN == '9' ]; then
    apt-get -y install elinks net-tools
else
    apt-get -y install elinks-lite
fi
apt-get clean
# Git
apt-get -y install git-core
apt-get clean
# Email
apt-get -y install exim4-config exim4-daemon-light
apt-get clean

#########
# Python
#########
# Install Libraries
if [ $DEBIAN == '9' ]; then
    apt-get -y install libgeos-c1v5
else
    apt-get -y install libgeos-c1
fi

# Install Python
#apt-get -y install python2.7
apt-get -y install python-dev
# 100 Mb of diskspace due to deps, so only if you want an advanced shell
#apt-get -y install ipython
apt-get clean
apt-get -y install python-lxml python-setuptools python-dateutil
apt-get clean
apt-get -y install python-serial
#apt-get -y install python-imaging python-reportlab
apt-get -y install python-imaging
apt-get -y install python-matplotlib
apt-get -y install python-pip
apt-get -y install python-requests
apt-get -y install python-xlwt
apt-get -y install build-essential
apt-get clean

# Upgrade ReportLab for Percentage support
#apt-get remove -y python-reportlab
#wget --no-check-certificate http://pypi.python.org/packages/source/r/reportlab/reportlab-3.3.0.tar.gz
#tar zxvf reportlab-3.3.0.tar.gz
#cd reportlab-3.3.0
#python setup.py install
#cd ..
pip install reportlab

# Upgrade Shapely for Simplify enhancements
#apt-get remove -y python-shapely
apt-get -y install libgeos-dev
#wget --no-check-certificate https://pypi.python.org/packages/e6/23/03ea2c965fe5ded97c0dd97c2cd659f1afb5c21f388ec68012d6d981cb7c/Shapely-1.5.17.tar.gz
#tar zxvf Shapely-1.5.17.tar.gz
#cd Shapely-1.5.17
#python setup.py install
#cd ..
pip install shapely

# Upgrade XLRD for XLS import support
#apt-get remove -y python-xlrd
#wget --no-check-certificate http://pypi.python.org/packages/source/x/xlrd/xlrd-0.9.4.tar.gz
#tar zxvf xlrd-0.9.4.tar.gz
#cd xlrd-0.9.4
#python setup.py install
#cd ..
pip install xlrd

#########
# Web2Py
#########
apt-get -y install libodbc1
# Install Web2Py
adduser --system --disabled-password web2py
addgroup web2py
cd /home
env GIT_SSL_NO_VERIFY=true git clone --recursive https://github.com/web2py/web2py.git
cd web2py
# 2.14.6
git reset --hard cda35fd
git submodule update --init --recursive
ln -s /home/web2py ~
cp -f /home/web2py/handlers/wsgihandler.py /home/web2py
cat << EOF > "/home/web2py/routes.py"
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

# Configure Matplotlib
mkdir /home/web2py/.matplotlib
chown web2py /home/web2py/.matplotlib
echo "os.environ['MPLCONFIGDIR'] = '/home/web2py/.matplotlib'" >> /home/web2py/wsgihandler.py
sed -i 's|TkAgg|Agg|' /etc/matplotlibrc

##############
# Sahana Eden
##############
# Install Sahana Eden
cd /home/web2py
cd applications
# @ToDo: Stable branch
env GIT_SSL_NO_VERIFY=true git clone https://github.com/sahana/eden.git
# Fix permissions
chown web2py ~web2py
chown web2py ~web2py/applications/admin/cache
chown web2py ~web2py/applications/admin/cron
chown web2py ~web2py/applications/admin/databases
chown web2py ~web2py/applications/admin/errors
chown web2py ~web2py/applications/admin/sessions
chown web2py ~web2py/applications/eden
chown web2py ~web2py/applications/eden/cache
chown web2py ~web2py/applications/eden/cron
mkdir -p ~web2py/applications/eden/databases
chown web2py ~web2py/applications/eden/databases
mkdir -p ~web2py/applications/eden/errors
chown web2py ~web2py/applications/eden/errors
chown web2py ~web2py/applications/eden/models
mkdir -p ~web2py/applications/eden/sessions
chown web2py ~web2py/applications/eden/sessions
chown web2py ~web2py/applications/eden/static/fonts
chown web2py ~web2py/applications/eden/static/img/markers
mkdir -p ~web2py/applications/eden/static/cache/chart
chown web2py -R ~web2py/applications/eden/static/cache
mkdir -p ~web2py/applications/eden/uploads/gis_cache
mkdir -p ~web2py/applications/eden/uploads/images
mkdir -p ~web2py/applications/eden/uploads/tracks
chown web2py ~web2py/applications/eden/uploads
chown web2py ~web2py/applications/eden/uploads/gis_cache
chown web2py ~web2py/applications/eden/uploads/images
chown web2py ~web2py/applications/eden/uploads/tracks
ln -s /home/web2py/applications/eden /home/web2py
ln -s /home/web2py/applications/eden ~

##########
# Cherokee
##########
# Old Debian version
#echo "deb http://apt.balocco.name squeeze main" >> /etc/apt/sources.list
#curl http://apt.balocco.name/key.asc | apt-key add -
#apt-get update
#apt-get -y --force-yes install cherokee libcherokee-mod-rrd
#apt-get clean
apt-get install -y autoconf automake libtool gettext rrdtool
cd /tmp
#env GIT_SSL_NO_VERIFY=true git clone --recursive https://github.com/cherokee/webserver.git
#cd webserver
wget https://github.com/cherokee/webserver/archive/master.zip
unzip master.zip
cd webserver-master
if [ $DEBIAN == '9' ]; then
    apt-get install -y libtool-bin
elif [ $DEBIAN == '8' ]; then
    apt-get install -y libtool-bin
fi
sh ./autogen.sh --prefix=/usr --localstatedir=/var --sysconfdir=/etc
make
make install

mkdir /var/log/cherokee
chown www-data:www-data /var/log/cherokee
mkdir -p /var/lib/cherokee/graphs
chown www-data:www-data -R /var/lib/cherokee

cat << EOF > "/etc/init.d/cherokee"
#! /bin/sh
#
# start/stop Cherokee web server

### BEGIN INIT INFO
# Provides:          cherokee
# Required-Start:    \$remote_fs \$network \$syslog
# Required-Stop:     \$remote_fs \$network \$syslog
# Should-Start:      \$named
# Should-Stop:       \$named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start the Cherokee Web server
# Description:       Start the Cherokee Web server
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/cherokee
NAME=cherokee
PIDFILE=/var/run/cherokee.pid

. /lib/lsb/init-functions

set -e

test -x \$DAEMON || exit 0

case "\$1" in
  start)        
        echo "Starting \$NAME web server "
        start-stop-daemon --start --oknodo --pidfile \$PIDFILE --exec \$DAEMON -b
        ;;

  stop)
        echo "Stopping \$NAME web server "
        start-stop-daemon --stop --oknodo --pidfile \$PIDFILE --exec \$DAEMON
        rm -f \$PIDFILE
        ;;

  restart)
        \$0 stop
        sleep 1
        \$0 start
        ;;

  reload|force-reload)
        echo "Reloading web server "
        if [ -f \$PIDFILE ]
            then
            PID=\$(cat \$PIDFILE)
            if ps p \$PID | grep \$NAME >/dev/null 2>&1
            then
                kill -HUP \$PID
            else
                echo "PID present, but \$NAME not found at PID \$PID - Cannot reload"
                exit 1
            fi
        else
            echo "No PID file present for \$NAME - Cannot reload"
            exit 1
        fi
        ;;

  status)
        # Strictly, LSB mandates us to return indicating the different statuses,
        # but that's not exactly Debian compatible - For further information:
        # http://www.freestandards.org/spec/refspecs/LSB_1.3.0/gLSB/gLSB/iniscrptact.html
        # http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=208010
        # ...So we just inform to the invoker and return success.
        echo "\$NAME web server status"
        if [ -e \$PIDFILE ] ; then
            PROCNAME=\$(ps -p \$(cat \$PIDFILE) -o comm=)
            if [ "x\$PROCNAME" = "x" ]; then
                echo "Not running, but PID file present"
            else
                if [ "\$PROCNAME" = "\$NAME" ]; then
                    echo "Running"
                else
                    echo "PID file points to process '\$PROCNAME', not '\$NAME'"
                fi
            fi
        else
            if PID=\$(pidofproc \$DAEMON); then
                echo "Running (PID \$PID), but PIDFILE not present"
            else
                echo "Not running\t"
            fi
        fi
        ;;

  *)
        N=/etc/init.d/\$NAME
        echo "Usage: \$N {start|stop|restart|reload|force-reload|status}" >&2
        exit 1
        ;;
esac

exit 0
EOF
chmod +x /etc/init.d/cherokee
update-rc.d cherokee defaults

CHEROKEE_CONF="/etc/cherokee/cherokee.conf"

# Install uWSGI
#apt-get install -y libxml2-dev
cd /tmp
wget http://projects.unbit.it/downloads/uwsgi-1.9.18.2.tar.gz
tar zxvf uwsgi-1.9.18.2.tar.gz
cd uwsgi-1.9.18.2
#cd uwsgi-1.2.6/buildconf
#wget http://eden.sahanafoundation.org/downloads/uwsgi_build.ini
#cd ..
#sed -i "s|, '-Werror'||" uwsgiconfig.py
#python uwsgiconfig.py --build uwsgi_build
python uwsgiconfig.py --build pyonly.ini
cp uwsgi /usr/local/bin

# Configure uwsgi

## Log rotation
cat << EOF > "/etc/logrotate.d/uwsgi"
/var/log/uwsgi/*.log {
       weekly
       rotate 10
       copytruncate
       delaycompress
       compress
       notifempty
       missingok
}
EOF

## Add Scheduler config

cat << EOF > "/home/web2py/run_scheduler.py"
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


cat << EOF > "/home/web2py/uwsgi.ini"
[uwsgi]
uid = web2py
gid = web2py
chdir = /home/web2py/
module = wsgihandler
mule = run_scheduler.py
workers = 4
cheap = true
idle = 1000
harakiri = 1000
pidfile = /tmp/uwsgi-prod.pid
daemonize = /var/log/uwsgi/prod.log
socket = 127.0.0.1:59025
master = true
EOF

touch /tmp/uwsgi-prod.pid
chown web2py: /tmp/uwsgi-prod.pid

mkdir -p /var/log/uwsgi
chown web2py: /var/log/uwsgi

# Init script for uwsgi

cat << EOF > "/etc/init.d/uwsgi-prod"
#! /bin/bash
# /etc/init.d/uwsgi-prod
#

daemon=/usr/local/bin/uwsgi
pid=/tmp/uwsgi-prod.pid
args="/home/web2py/uwsgi.ini"

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
        echo "Usage: /etc/init.d/uwsgi {start|stop|restart|reload}"
        exit 1
    ;;
esac
exit 0
EOF

chmod a+x /etc/init.d/uwsgi-prod
update-rc.d uwsgi-prod defaults

# Configure Cherokee
# If using an Alternate Theme then can add a rule for that: static/themes/<theme>/img

mv "$CHEROKEE_CONF" /tmp
cat << EOF > "$CHEROKEE_CONF"
config!version = 001002002
server!bind!1!port = 80
server!collector = rrd
server!fdlimit = 10240
server!group = www-data
server!ipv6 = 0
server!keepalive = 1
server!keepalive_max_requests = 500
server!panic_action = /usr/share/cherokee/cherokee-panic
server!pid_file = /var/run/cherokee.pid
server!server_tokens = product
server!timeout = 1000
server!user = www-data
vserver!10!collector!enabled = 1
vserver!10!directory_index = index.html
vserver!10!document_root = /var/www
vserver!10!error_writer!filename = /var/log/cherokee/cherokee.error
vserver!10!error_writer!type = file
vserver!10!logger = combined
vserver!10!logger!access!buffsize = 16384
vserver!10!logger!access!filename = /var/log/cherokee/cherokee.access
vserver!10!logger!access!type = file
vserver!10!nick = default
vserver!10!rule!10!handler = common
vserver!10!rule!10!handler!iocache = 1
vserver!10!rule!10!match = default
vserver!20!collector!enabled = 1
vserver!20!directory_index = index.html
vserver!20!document_root = /var/www
vserver!20!error_writer!filename = /var/log/cherokee/cherokee.error
vserver!20!error_writer!type = file
vserver!20!logger = combined
vserver!20!logger!access!buffsize = 16384
vserver!20!logger!access!filename = /var/log/cherokee/cherokee.access
vserver!20!logger!access!type = file
vserver!20!match = wildcard
vserver!20!match!domain!1 = *
vserver!20!match!nick = 0
vserver!20!nick = maintenance
vserver!20!rule!210!handler = file
vserver!20!rule!210!match = fullpath
vserver!20!rule!210!match!fullpath!1 = /maintenance.html
vserver!20!rule!110!handler = redir
vserver!20!rule!110!handler!rewrite!10!regex = ^/*
vserver!20!rule!110!handler!rewrite!10!show = 1
vserver!20!rule!110!handler!rewrite!10!substring = /maintenance.html
vserver!20!rule!110!match = directory
vserver!20!rule!110!match!directory = /
vserver!20!rule!10!handler = common
vserver!20!rule!10!handler!iocache = 1
vserver!20!rule!10!match = default
vserver!30!collector!enabled = 1
vserver!30!directory_index = index.html
vserver!30!document_root = /var/www
vserver!30!error_handler = error_redir
vserver!30!error_handler!503!show = 0
vserver!30!error_handler!503!url = /maintenance.html
vserver!30!error_writer!filename = /var/log/cherokee/cherokee.error
vserver!30!error_writer!type = file
vserver!30!logger = combined
vserver!30!logger!access!buffsize = 16384
vserver!30!logger!access!filename = /var/log/cherokee/cherokee.access
vserver!30!logger!access!type = file
vserver!30!match = wildcard
vserver!30!match!domain!1 = *
vserver!30!match!nick = 0
vserver!30!nick = Production
vserver!30!rule!700!expiration = epoch
vserver!30!rule!700!expiration!caching = public
vserver!30!rule!700!expiration!caching!must-revalidate = 1
vserver!30!rule!700!expiration!caching!no-store = 0
vserver!30!rule!700!expiration!caching!no-transform = 0
vserver!30!rule!700!expiration!caching!proxy-revalidate = 1
vserver!30!rule!700!handler = common
vserver!30!rule!700!handler!allow_dirlist = 0
vserver!30!rule!700!handler!allow_pathinfo = 0
vserver!30!rule!700!match = fullpath
vserver!30!rule!700!match!fullpath!1 = /maintenance.html
vserver!30!rule!500!document_root = /home/web2py/applications/eden/static
vserver!30!rule!500!encoder!deflate = allow
vserver!30!rule!500!encoder!gzip = allow
vserver!30!rule!500!expiration = time
vserver!30!rule!500!expiration!time = 7d
vserver!30!rule!500!handler = file
vserver!30!rule!500!match = fullpath
vserver!30!rule!500!match!fullpath!1 = /favicon.ico
vserver!30!rule!500!match!fullpath!2 = /robots.txt
vserver!30!rule!500!match!fullpath!3 = /crossdomain.xml
vserver!30!rule!400!document_root = /home/web2py/applications/eden/static/img
vserver!30!rule!400!encoder!deflate = forbid
vserver!30!rule!400!encoder!gzip = forbid
vserver!30!rule!400!expiration = time
vserver!30!rule!400!expiration!caching = public
vserver!30!rule!400!expiration!caching!must-revalidate = 0
vserver!30!rule!400!expiration!caching!no-store = 0
vserver!30!rule!400!expiration!caching!no-transform = 0
vserver!30!rule!400!expiration!caching!proxy-revalidate = 0
vserver!30!rule!400!expiration!time = 7d
vserver!30!rule!400!handler = file
vserver!30!rule!400!match = directory
vserver!30!rule!400!match!directory = /eden/static/img/
vserver!30!rule!400!match!final = 1
vserver!30!rule!300!document_root = /home/web2py/applications/eden/static
vserver!30!rule!300!encoder!deflate = allow
vserver!30!rule!300!encoder!gzip = allow
vserver!30!rule!300!expiration = epoch
vserver!30!rule!300!expiration!caching = public
vserver!30!rule!300!expiration!caching!must-revalidate = 1
vserver!30!rule!300!expiration!caching!no-store = 0
vserver!30!rule!300!expiration!caching!no-transform = 0
vserver!30!rule!300!expiration!caching!proxy-revalidate = 1
vserver!30!rule!300!handler = file
vserver!30!rule!300!match = directory
vserver!30!rule!300!match!directory = /eden/static/
vserver!30!rule!300!match!final = 1
vserver!30!rule!200!encoder!deflate = allow
vserver!30!rule!200!encoder!gzip = allow
vserver!30!rule!200!handler = uwsgi
vserver!30!rule!200!handler!balancer = round_robin
vserver!30!rule!200!handler!balancer!source!10 = 1
vserver!30!rule!200!handler!check_file = 0
vserver!30!rule!200!handler!error_handler = 1
vserver!30!rule!200!handler!modifier1 = 0
vserver!30!rule!200!handler!modifier2 = 0
vserver!30!rule!200!handler!pass_req_headers = 1
vserver!30!rule!200!match = directory
vserver!30!rule!200!match!directory = /
vserver!30!rule!100!handler = common
vserver!30!rule!100!handler!iocache = 1
vserver!30!rule!100!match = default
source!1!env_inherited = 1
source!1!group = web2py
source!1!host = 127.0.0.1:59025
source!1!interpreter = /usr/local/bin/uwsgi -s 127.0.0.1:59025 -x /home/web2py/uwsgi.xml
source!1!nick = uWSGI 1
source!1!timeout = 1000
source!1!type = host
source!1!user = web2py
EOF

grep 'icons!' /tmp/cherokee.conf >> "$CHEROKEE_CONF"
grep 'mime!' /tmp/cherokee.conf >> "$CHEROKEE_CONF"

cat << EOF >> "$CHEROKEE_CONF"
admin!ows!enabled = 0
EOF

# For a static home page, push 400->500 & 300->400 & insert this
#vserver!30!rule!300!document_root = /home/web2py/applications/eden/static
#vserver!30!rule!300!handler = redir
#vserver!30!rule!300!handler!rewrite!10!regex = ^.*$
#vserver!30!rule!300!handler!rewrite!10!show = 1
#vserver!30!rule!300!handler!rewrite!10!substring = /eden/static/index.html
#vserver!30!rule!300!match = and
#vserver!30!rule!300!match!final = 1
#vserver!30!rule!300!match!left = fullpath
#vserver!30!rule!300!match!left!fullpath!1 = /
#vserver!30!rule!300!match!right = not
#vserver!30!rule!300!match!right!right = header
#vserver!30!rule!300!match!right!right!complete = 0
#vserver!30!rule!300!match!right!right!header = Cookie
#vserver!30!rule!300!match!right!right!match = re
#vserver!30!rule!300!match!right!right!type = regex

cat << EOF > "/var/www/maintenance.html"
<html><body><h1>Site Maintenance</h1>Please try again later...</body></html>
EOF


/etc/init.d/cherokee restart


############
# PostgreSQL
############
cat << EOF > "/etc/apt/sources.list.d/pgdg.list"
deb http://apt.postgresql.org/pub/repos/apt/ $DEBIAN_NAME-pgdg main
EOF

wget --no-check-certificate https://www.postgresql.org/media/keys/ACCC4CF8.asc
apt-key add ACCC4CF8.asc
apt-get update

apt-get -y install postgresql-9.6 python-psycopg2 ptop pgtop
apt-get -y install postgresql-9.6-postgis-2.3

# Tune PostgreSQL
cat << EOF >> "/etc/sysctl.conf"
## Increase Shared Memory available for PostgreSQL
# 512Mb
#kernel.shmmax = 279134208
# 1024Mb (may need more)
kernel.shmmax = 552992768
kernel.shmall = 2097152
EOF
#sysctl -w kernel.shmmax=279134208 # For 512 MB RAM
sysctl -w kernel.shmmax=552992768 # For 1024 MB RAM
sysctl -w kernel.shmall=2097152

sed -i 's|#track_counts = on|track_counts = on|' /etc/postgresql/9.6/main/postgresql.conf
sed -i 's|#autovacuum = on|autovacuum = on|' /etc/postgresql/9.6/main/postgresql.conf
sed -i 's|max_connections = 100|max_connections = 20|' /etc/postgresql/9.6/main/postgresql.conf
# 1024Mb RAM: (e.g. t2.micro)
sed -i 's|#effective_cache_size = 4GB|effective_cache_size = 512MB|' /etc/postgresql/9.6/main/postgresql.conf
sed -i 's|#work_mem = 4MB|work_mem = 8MB|' /etc/postgresql/9.6/main/postgresql.conf
# If only 512 RAM, activate post-install via pg512 script

#####################
# Management scripts
#####################
cat << EOF > "/usr/local/bin/backup"
#!/bin/sh
mkdir /var/backups/eden
chown postgres /var/backups/eden
NOW=\$(date +"%Y-%m-%d")
su -c - postgres "pg_dump -c sahana > /var/backups/eden/sahana-\$NOW.sql"
#su -c - postgres "pg_dump -Fc gis > /var/backups/eden/gis.dmp"
OLD=\$(date --date='7 day ago' +"%Y-%m-%d")
rm -f /var/backups/eden/sahana-\$OLD.sql
mkdir /var/backups/eden/uploads
tar -cf /var/backups/eden/uploads/uploadsprod-\$NOW.tar -C /home/web2py/applications/eden  ./uploads
bzip2 /var/backups/eden/uploads/uploadsprod-\$NOW.tar
rm -f /var/backups/eden/uploads/uploadsprod-\$OLD.tar.bz2
EOF
chmod +x /usr/local/bin/backup

cat << EOF > "/usr/local/bin/compile"
#!/bin/bash
/etc/init.d/uwsgi-prod stop
cd ~web2py
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-prod start
EOF
chmod +x /usr/local/bin/compile

cat << EOF > "/usr/local/bin/pull"
#!/bin/sh

/etc/init.d/uwsgi-prod stop
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
git reset --hard HEAD
git pull
rm -rf compiled
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
cd ~web2py
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-prod start
EOF
chmod +x /usr/local/bin/pull

cat << EOF > "/usr/local/bin/migrate"
#!/bin/sh
/etc/init.d/uwsgi-prod stop
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
rm -rf compiled
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
cd ~web2py
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-prod start
EOF
chmod +x /usr/local/bin/migrate

cat << EOF > "/usr/local/bin/revert"
#!/bin/sh
git reset --hard HEAD
EOF
chmod +x /usr/local/bin/revert

cat << EOF > "/usr/local/bin/w2p"
#!/bin/sh
cd ~web2py
python web2py.py -S eden -M
EOF
chmod +x /usr/local/bin/w2p

cat << EOF2 > "/usr/local/bin/clean"
#!/bin/sh
/etc/init.d/uwsgi-prod stop
cd ~web2py/applications/eden
rm -rf databases/*
rm -f errors/*
rm -rf sessions/*
rm -rf uploads/*
pkill -f 'postgres: sahana sahana'
sudo -H -u postgres dropdb sahana
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
sed -i 's/settings.base.prepopulate = 0/#settings.base.prepopulate = 0/g' models/000_config.py
rm -rf compiled
su -c - postgres "createdb -O sahana -E UTF8 sahana -T template0"
#su -c - postgres "createlang plpgsql -d sahana"
#su -c - postgres "psql -q -d sahana -f /usr/share/postgresql/9.6/extension/postgis--2.3.0.sql"
su -c - postgres "psql -q -d sahana -c 'CREATE EXTENSION postgis;'"
su -c - postgres "psql -q -d sahana -c 'grant all on geometry_columns to sahana;'"
su -c - postgres "psql -q -d sahana -c 'grant all on spatial_ref_sys to sahana;'"
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
sed -i 's/#settings.base.prepopulate = 0/settings.base.prepopulate = 0/g' models/000_config.py
cd ~web2py
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
/etc/init.d/uwsgi-prod start
if [ -e /home/data/import.py ]; then
    sudo -H -u web2py python web2py.py -S eden -M -R /home/data/import.py
fi
EOF2
chmod +x /usr/local/bin/clean

cat << EOF > "/usr/local/bin/pg1024"
#!/bin/sh
sed -i 's|kernel.shmmax = 279134208|#kernel.shmmax = 279134208|' /etc/sysctl.conf
sed -i 's|#kernel.shmmax = 552992768|kernel.shmmax = 552992768|' /etc/sysctl.conf
sysctl -w kernel.shmmax=552992768
sed -i 's|shared_buffers = 128MB|shared_buffers = 256MB|' /etc/postgresql/9.6/main/postgresql.conf
sed -i 's|effective_cache_size = 256MB|effective_cache_size = 512MB|' /etc/postgresql/9.6/main/postgresql.conf
sed -i 's|work_mem = 4MB|work_mem = 8MB|' /etc/postgresql/9.6/main/postgresql.conf
/etc/init.d/postgresql restart
EOF
chmod +x /usr/local/bin/pg1024

cat << EOF > "/usr/local/bin/pg512"
#!/bin/sh
sed -i 's|#kernel.shmmax = 279134208|kernel.shmmax = 279134208|' /etc/sysctl.conf
sed -i 's|kernel.shmmax = 552992768|#kernel.shmmax = 552992768|' /etc/sysctl.conf
sysctl -w kernel.shmmax=279134208
sed -i 's|shared_buffers = 256MB|shared_buffers = 128MB|' /etc/postgresql/9.6/main/postgresql.conf
sed -i 's|effective_cache_size = 512MB|effective_cache_size = 256MB|' /etc/postgresql/9.6/main/postgresql.conf
sed -i 's|work_mem = 8MB|work_mem = 4MB|' /etc/postgresql/9.6/main/postgresql.conf
/etc/init.d/postgresql restart
EOF
chmod +x /usr/local/bin/pg512

apt-get clean

# END
