#!/bin/bash

# Script to configure an Eden server
# - assumes that install-eden-cherokee-postgis.sh has been run

echo -e "What domain name should we use? : \c "
read DOMAIN

echo -e "What host name should we use? : \c "
read hostname
sitename=$hostname".$DOMAIN"

echo -e "What template should we use? : \c "
read template
if [[ ! "$template" ]]; then
    template="default"
fi

# @ToDo: Generate a random password
echo Note that web2py will not work with passwords with an @ in them
echo -e "What is the new PostgreSQL password: \c "
read password

echo "Now reconfiguring system to use the hostname: $hostname"

cd /etc
filename="hosts"
sed -i "s|localhost.localdomain localhost|$sitename $hostname localhost.localdomain localhost|" $filename

cd /etc
filename="hostname"
echo $hostname > $filename

cd /etc
filename="mailname"
echo $sitename >  $filename

# Update system (in case run at a much later time than the install script)
apt-get update
apt-get upgrade -y
# Disabled to ensure we keep Stable version from Install
#cd ~web2py
#git pull
cd ~web2py/applications/eden
git pull
# -----------------------------------------------------------------------------
# Email
# -----------------------------------------------------------------------------
echo configure for Internet mail delivery
dpkg-reconfigure exim4-config

# -----------------------------------------------------------------------------
# Sahana Eden
# -----------------------------------------------------------------------------
echo "Setting up Sahana"

# Copy Templates
cp ~web2py/applications/eden/modules/templates/000_config.py ~web2py/applications/eden/models

sed -i "s|settings.base.template = \"default\"|settings.base.template = \"$template\"|" ~web2py/applications/eden/models/000_config.py
sed -i 's|EDITING_CONFIG_FILE = False|EDITING_CONFIG_FILE = True|' ~web2py/applications/eden/models/000_config.py
sed -i "s|akeytochange|$sitename$password|" ~web2py/applications/eden/models/000_config.py
sed -i "s|#settings.base.public_url = \"http://127.0.0.1:8000\"|settings.base.public_url = \"http://$sitename\"|" ~web2py/applications/eden/models/000_config.py
sed -i 's|#settings.base.cdn = True|settings.base.cdn = True|' ~web2py/applications/eden/models/000_config.py

# PostgreSQL
echo "CREATE USER sahana WITH PASSWORD '$password';" > /tmp/pgpass.sql
su -c - postgres "psql -q -d template1 -f /tmp/pgpass.sql"
rm -f /tmp/pgpass.sql
su -c - postgres "createdb -O sahana -E UTF8 sahana -T template0"
#su -c - postgres "createlang plpgsql -d sahana"

# PostGIS
#su -c - postgres "psql -q -d sahana -f /usr/share/postgresql/9.6/extension/postgis--2.3.0.sql"
su -c - postgres "psql -q -d sahana -c 'CREATE EXTENSION postgis;'"
su -c - postgres "psql -q -d sahana -c 'GRANT ALL ON geometry_columns TO sahana;'"
su -c - postgres "psql -q -d sahana -c 'GRANT ALL ON spatial_ref_sys TO sahana;'"

# Configure Database
sed -i 's|#settings.database.db_type = "postgres"|settings.database.db_type = "postgres"|' ~web2py/applications/eden/models/000_config.py
sed -i "s|#settings.database.password = \"password\"|settings.database.password = \"$password\"|" ~web2py/applications/eden/models/000_config.py
sed -i 's|#settings.gis.spatialdb = True|settings.gis.spatialdb = True|' ~web2py/applications/eden/models/000_config.py

# Create the Tables & Populate with base data
sed -i 's|settings.base.migrate = False|settings.base.migrate = True|' ~web2py/applications/eden/models/000_config.py
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py

# Configure for Production
sed -i 's|#settings.base.prepopulate = 0|settings.base.prepopulate = 0|' ~web2py/applications/eden/models/000_config.py
sed -i 's|settings.base.migrate = True|settings.base.migrate = False|' ~web2py/applications/eden/models/000_config.py
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py

# Schedule backups for 02:01 daily
echo "1 2   * * * root    /usr/local/bin/backup" >> "/etc/crontab"

#read -p "Press any key to Reboot..."
echo "Now rebooting.."
reboot

# END
