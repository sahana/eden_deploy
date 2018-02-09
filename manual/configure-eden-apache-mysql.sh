#!/bin/bash

# Script to configure an Eden server
# - assumes that install-eden-apache-mysql.sh has been run

# Which OS are we running?
read -d . DEBIAN < /etc/debian_version

if [ $DEBIAN == '8' ]; then
    DEBIAN_NAME='jessie'
    # Apache 2.4
    extension='.conf'
    GRANT='Require all granted'
else
    DEBIAN_NAME='wheezy'
    # Apache 2.2
    extension=''
    GRANT='    Order deny,allow
    Allow from all'
fi

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

echo -e "What is the current root MySQL password: \c "
read rootpw

# @ToDo: Generate a random password
echo Note that web2py will not work with passwords with an @ in them
echo -e "What should be the MySQL password for user 'sahana'? \c "
read password

echo "Now reconfiguring system"

cd /etc
filename="hosts"
sed -i "s|localdomain localhost|localdomain localhost $hostname|" $filename

cd /etc
filename="hostname"
echo $hostname > $filename

cd /etc
filename="mailname"
echo $sitename >  $filename

# -----------------------------------------------------------------------------
# Email
# -----------------------------------------------------------------------------
echo configure for Internet mail delivery
dpkg-reconfigure exim4-config

# -----------------------------------------------------------------------------
# Update system
#   in case run at a much later time than the install script
# -----------------------------------------------------------------------------
apt-get update
apt-get upgrade -y
cd ~web2py/applications/eden
git pull

# -----------------------------------------------------------------------------
# Apache Web server
# -----------------------------------------------------------------------------
echo "Setting up Web server"

rm -f /etc/apache2/sites-enabled/000-default$extension
cat << EOF > "/etc/apache2/sites-available/production$extension"
<VirtualHost *:80>
  ServerName $hostname.$DOMAIN
  ServerAdmin webmaster@$DOMAIN
  DocumentRoot /home/web2py/applications 

  WSGIScriptAlias / /home/web2py/wsgihandler.py
  ## Edit the process and the maximum-requests to reflect your RAM 
  WSGIDaemonProcess web2py user=web2py group=web2py home=/home/web2py processes=4 maximum-requests=100

  RewriteEngine On
  # Stop GoogleBot from slowing us down
  RewriteRule .*robots\.txt$ /eden/static/robots.txt [L]
  # extract desired cookie value from multiple-cookie HTTP header
  #RewriteCond %{HTTP_COOKIE} registered=([^;]+)
  # check that cookie value is correct
  #RewriteCond %1 ^yes$
  #RewriteRule ^/$ /eden/ [R,L]
  #RewriteRule ^/$ /eden/static/index.html [R,L]
  RewriteCond %{REQUEST_URI}    !/phpmyadmin(.*)
  RewriteCond %{REQUEST_URI}    !/eden/(.*)
  RewriteRule /(.*) /eden/$1 [R]

  ### static files do not need WSGI
  <LocationMatch "^(/[\w_]*/static/.*)">
    Order Allow,Deny
    Allow from all
    
    SetOutputFilter DEFLATE
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    Header append Vary User-Agent env=!dont-vary

    ExpiresActive On
    ExpiresByType text/html "access plus 1 day"
    ExpiresByType text/javascript "access plus 1 week"
    ExpiresByType text/css "access plus 2 weeks"
    ExpiresByType image/ico "access plus 1 month"
    ExpiresByType image/gif "access plus 1 month"
    ExpiresByType image/jpeg "access plus 1 month"
    ExpiresByType image/jpg "access plus 1 month"
    ExpiresByType image/png "access plus 1 month"
    ExpiresByType application/x-shockwave-flash "access plus 1 month"
  </LocationMatch>
  ### everything else goes over WSGI
  <Location "/">
    $GRANT
    WSGIProcessGroup web2py
  </Location>

  ErrorLog /var/log/apache2/$hostname_error.log
  LogLevel warn
  CustomLog /var/log/apache2/$hostname_access.log combined
</VirtualHost>
EOF
a2ensite production
apache2ctl restart

cat << EOF > "/etc/apache2/sites-available/maintenance$extension"
<VirtualHost *:80>
  ServerName $hostname.$DOMAIN
  ServerAdmin webmaster@$DOMAIN
  DocumentRoot /var/www

  RewriteEngine On
  RewriteCond %{REQUEST_URI} !/phpmyadmin(.*)
  RewriteRule ^/(.*) /maintenance.html

  <Location "/">
    $GRANT
  </Location>

  ErrorLog /var/log/apache2/maintenance_error.log
  LogLevel warn
  CustomLog /var/log/apache2/maintenance_access.log combined
</VirtualHost>
EOF

# -----------------------------------------------------------------------------
# MySQL Database
# -----------------------------------------------------------------------------
echo "Setting up Database"

# Allow root user to access database without entering password
cat << EOF > "/root/.my.cnf"
[client]
user=root
EOF

echo "password='$rootpw'" >> "/root/.my.cnf"

# Create database
mysqladmin create sahana

# Create user for Sahana application
echo "CREATE USER 'sahana'@'localhost' IDENTIFIED BY '$password';" > "/tmp/mypass"
echo "GRANT ALL PRIVILEGES ON *.* TO 'sahana'@'localhost' WITH GRANT OPTION;" >> "/tmp/mypass"
mysql < /tmp/mypass
rm -f /tmp/mypass

# Schedule backups for 02:01 daily
echo "1 2   * * * * root    /usr/local/bin/backup" >> "/etc/crontab"

# -----------------------------------------------------------------------------
# Sahana Eden
# -----------------------------------------------------------------------------
echo "Setting up Sahana"

# Copy Templates
cp ~web2py/applications/eden/modules/templates/000_config.py ~web2py/applications/eden/models

sed -i "s|settings.base.template = \"default\"|settings.base.template = \"$template\"|" ~web2py/applications/eden/models/000_config.py
sed -i 's|EDITING_CONFIG_FILE = False|EDITING_CONFIG_FILE = True|' ~web2py/applications/eden/models/000_config.py
sed -i "s|akeytochange|$sitename$password|" ~web2py/applications/eden/models/000_config.py
sed -i "s|127.0.0.1:8000|$sitename|" ~web2py/applications/eden/models/000_config.py
sed -i 's|base.cdn = False|base.cdn = True|' ~web2py/applications/eden/models/000_config.py

# Configure Database
sed -i 's|#settings.database.db_type = "mysql"|settings.database.db_type = "mysql"|' ~web2py/applications/eden/models/000_config.py
sed -i "s|#settings.database.password = \"password\"|settings.database.password = \"$password\"|" ~web2py/applications/eden/models/000_config.py

# Create the Tables & Populate with base data
sed -i 's|settings.base.prepopulate = 0|settings.base.prepopulate = 1|' ~web2py/applications/eden/models/000_config.py
sed -i 's|settings.base.migrate = False|settings.base.migrate = True|' ~web2py/applications/eden/models/000_config.py
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py

# Configure for Production
sed -i 's|settings.base.prepopulate = 1|settings.base.prepopulate = 0|' ~web2py/applications/eden/models/000_config.py
sed -i 's|settings.base.migrate = True|settings.base.migrate = False|' ~web2py/applications/eden/models/000_config.py
cd ~web2py
sudo -H -u web2py python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py

# Add Scheduler
sed -i 's|exit 0|cd ~web2py \&\& python web2py.py -K eden -Q >/dev/null 2>\&1 \&|' /etc/rc.local
echo "exit 0" >> /etc/rc.local

#read -p "Press any key to Reboot..."
echo "Now rebooting.."
reboot

# END
