# CLI script to upgrade Web2Py from 2.14.6 to 2.16.1
# - this is designed to be used with a Cherokee/PostGIS installation

# Procedure:
# - copy fieldnames.py to the web2py folder
# - bash upgrade_web2py.sh

# Notes for other systems:
# SQLite just requires a standard migration
# MySQL upgrades require a fake_migrate before the migration to avoid a long migration (>1 hour), script may come later if-required.

# Prepare upgrade:
# Stop server
/etc/init.d/uwsgi-prod stop

# Backup DB
/usr/local/bin/backup

# Remove compiled
cd ~web2py/eden
rm -rf compiled 

# Upgrade Eden (to ensure you have the fixes for current Web2Py)
git pull

# PostgreSQL-only: Execute this script with OLD web2py (2.14.6):
cd ~web2py
python web2py.py -S eden -M -R fieldnames.py

# Update web2py to 2.16.1
git pull
git reset --hard 7035398
git submodule update

# Patch PyDAL (Scheduler fix)
sed -i 's/credential_decoder = lambda cred: urllib.unquote(cred)/credential_decoder = lambda cred: unquote(cred)/' gluon/packages/dal/pydal/base.py

# Run a Migration with NEW web2py (2.16.1):
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = False/settings.base.migrate = True/g' models/000_config.py
# MySQL
#sed -i 's/#settings.base.fake_migrate = True/settings.base.fake_migrate = True/g' models/000_config.py
cd ~web2py
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/noop.py
cd ~web2py/applications/eden
sed -i 's/settings.base.migrate = True/settings.base.migrate = False/g' models/000_config.py
# MySQL
#sed -i 's/settings.base.fake_migrate = True/#settings.base.fake_migrate = True/g' models/000_config.py

# Compile
cd ~web2py
python web2py.py -S eden -M -R applications/eden/static/scripts/tools/compile.py

# Start server
/etc/init.d/uwsgi-prod start
