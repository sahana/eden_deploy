#!/bin/bash

# Script to turn a generic Debian Wheezy or Jessie box into an Eden server
# with Apache & MySQL

# Which OS are we running?
read -d . DEBIAN < /etc/debian_version

if [ $DEBIAN == '8' ]; then
    DEBIAN_NAME='jessie'
    # Apache 2.4
    extension='.conf'
else
    DEBIAN_NAME='wheezy'
    # Apache 2.2
    extension=''
fi

# Update system
apt-get update
apt-get upgrade -y

# Install Admin Tools
apt-get install -y unzip psmisc mlocate telnet lrzsz vim elinks-lite rcconf htop sudo
# Install Git
apt-get install -y git-core
# Email
apt-get -y install exim4-config exim4-daemon-light

########
# MySQL
########
apt-get -y install mysql-server python-mysqldb phpmyadmin mytop

# Tune for smaller RAM setups
sed -i 's|query_cache_size        = 16M|query_cache_size = 1M|' /etc/mysql/my.cnf
sed -i 's|key_buffer              = 16M|key_buffer = 1M|' /etc/mysql/my.cnf
sed -i 's|max_allowed_packet      = 16M|max_allowed_packet = 1M|' /etc/mysql/my.cnf

/etc/init.d/mysql restart

#########
# Apache
#########
apt-get -y install libapache2-mod-wsgi
a2enmod rewrite
a2enmod deflate
a2enmod headers
a2enmod expires

# Enable Basic Authentication for WebServices
sed -i 's|</IfModule>|WSGIPassAuthorization On|' /etc/apache2/mods-enabled/wsgi.conf
echo "</IfModule>" >> /etc/apache2/mods-enabled/wsgi.conf

# Prevent Memory leaks from killing servers
sed -i 's|MaxRequestsPerChild   0|MaxRequestsPerChild 300|' /etc/apache2/apache2.conf

# Tune for smaller RAM setups
sed -i 's|MinSpareServers       5|MinSpareServers 3|' /etc/apache2/apache2.conf
sed -i 's|MaxSpareServers      10|MaxSpareServers 6|' /etc/apache2/apache2.conf

apache2ctl restart

# Holding Page for Maintenance windows
cat << EOF > "/var/www/maintenance.html"
<html><body><h1>Site Maintenance</h1>Please try again later...</body></html>
EOF

#########
# Python
#########
# Install Libraries
apt-get -y install libgeos-c1

# Install Python
#apt-get -y install python2.6
apt-get -y install python-dev
# 100 Mb of diskspace due to deps, so only if you want an advanced shell
#apt-get -y install ipython
apt-get -y install python-lxml python-setuptools python-dateutil
apt-get -y install python-serial
#apt-get -y install python-imaging python-reportlab
apt-get -y install python-imaging
apt-get -y install python-matplotlib
apt-get -y install python-pip
apt-get -y install python-requests
apt-get -y install python-xlwt

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
git clone --recursive git://github.com/web2py/web2py.git
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
cd web2py
cd applications
# @ToDo: Stable branch
git clone git://github.com/sahana/eden.git
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
chown web2py ~web2py/applications/eden/errors
chown web2py ~web2py/applications/eden/models
mkdir -p ~web2py/applications/eden/sessions
chown web2py ~web2py/applications/eden/sessions
chown web2py ~web2py/applications/eden/static/fonts
chown web2py ~web2py/applications/eden/static/img/markers
mkdir -p ~web2py/applications/eden/static/cache/chart
chown web2py -R ~web2py/applications/eden/static/cache
chown web2py ~web2py/applications/eden/uploads
mkdir -p ~web2py/applications/eden/uploads/gis_cache
mkdir -p ~web2py/applications/eden/uploads/images
mkdir -p ~web2py/applications/eden/uploads/tracks
chown web2py ~web2py/applications/eden/uploads/gis_cache
chown web2py ~web2py/applications/eden/uploads/images
chown web2py ~web2py/applications/eden/uploads/tracks
ln -s /home/web2py/applications/eden ~

#####################
# Management scripts
#####################
cat << EOF > "/usr/local/bin/backup"
#!/bin/sh
NOW=\$(date +"%Y-%m-%d")
mysqldump sahana > /root/backup-\$NOW.sql
gzip -9 /root/backup-\$NOW.sql
OLD=\$(date --date='7 day ago' +"%Y-%m-%d")
rm -f /root/backup-\$OLD.sql.gz
EOF
chmod +x /usr/local/bin/backup

cat << EOF > "/usr/local/bin/compile"
#!/bin/sh
cd ~web2py
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py
apache2ctl restart
EOF
chmod +x /usr/local/bin/compile

cat << EOF > "/usr/local/bin/maintenance"
#!/bin/sh

# Script to activate/deactivate the maintenance site

# Can provide the option 'off' to disable the maintenance site
if [ "\$1" != "off" ]; then
    # Stop the Scheduler
    killall python
    # Deactivate the Production Site
    a2dissite production$extension
    # Activate the Maintenance Site
    a2ensite maintenance$extension
else
    # Deactivate the Maintenance Site
    a2dissite maintenance$extension
    # Activate the Production Site
    a2ensite production$extension
    # Start the Scheduler
    cd ~web2py && sudo -H -u web2py nohup python web2py.py -K eden -Q >/dev/null 2>&1 &
fi 
apache2ctl restart
EOF
chmod +x /usr/local/bin/maintenance

cat << EOF > "/usr/local/bin/pull"
#!/bin/sh
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
git pull
/usr/local/bin/maintenance
rm -rf compiled
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
/usr/local/bin/compile
/usr/local/bin/maintenance off
EOF
chmod +x /usr/local/bin/pull

# Change the value of prepopulate, if-necessary
cat << EOF > "/usr/local/bin/clean"
#!/bin/sh
/usr/local/bin/maintenance
cd ~web2py/applications/eden
rm -rf databases/*
rm -f errors/*
rm -rf sessions/*
rm -rf uploads/*
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
sed -i 's/settings.base.prepopulate = 0/#settings.base.prepopulate = 0/g' models/000_config.py
rm -rf compiled
mysqladmin -f drop sahana
mysqladmin create sahana
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
sed -i 's/#settings.base.prepopulate = 0/settings.base.prepopulate = 0/g' models/000_config.py
/usr/local/bin/maintenance off
/usr/local/bin/compile
EOF
chmod +x /usr/local/bin/clean

cat << EOF > "/usr/local/bin/w2p"
#!/bin/sh
cd ~web2py
python web2py.py -S eden -M
EOF
chmod +x /usr/local/bin/w2p

# END