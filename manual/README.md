Deployment of Eden with Manual Scripts
--------------------------------------

http://eden.sahanafoundation.org/wiki/InstallationGuidelines/Linux/Server

These scripts can be used to deploy Eden on a single, usually virtual, machine running Debian Linux versions 7, 8 or 9

There are 2 alternative stacks:
* Cherokee + PostGIS
    install-eden-cherokee-postgis.sh
    configure-eden-cherokee-postgis.sh
* Apache + MySQL
    install-eden-apache-mysql.sh
    configure-eden-apache-mysql.sh

Alternative possibilities exist, but these scripts cannot be used as-is for that:
* Apache + PostGIS on a single, usually virtual, machine
* Cherokee + MySQL on a single, usually virtual, machine
* Cherokee + Eden on one machine + PostGIS on a second machine


Additional scripts:

* Add a Test instance to the same box as Production
    add_test_site.sh

* Add a Demo instance to the same box as Production/Test
    add_demo_site.sh

* Upgrade Web2Py from 2.14.6 to 2.16.1
    upgrade_web2py.sh
    fieldnames.py

