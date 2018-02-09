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
if [[ "$1" = "prod" ]]; then
    DATABASE="sahana"
else
    DATABASE="sahana-$INSTANCE"
fi
echo >&2 "Cleaning instance: $INSTANCE"
echo >&2 "Dropping database: $DATABASE"
set +e
pkill -f "postgres: sahana $DATABASE"
sudo -H -u postgres dropdb $DATABASE
set -e
echo >&2 "Creating database: $DATABASE"
su -c - postgres "createdb -O sahana -E UTF8 -l en_US.UTF-8 $DATABASE -T template0"
if [[ "$1" = "test" ]]; then
    echo >&2 "Refreshing database from Production: $DATABASE"
    su -c - postgres "pg_dump -c sahana > /tmp/sahana.sql"
    su -c - postgres "psql -f /tmp/sahana.sql $DATABASE"
else
    echo >&2 "Migrating/Populating database: $DATABASE"
    #su -c - postgres "createlang plpgsql -d $DATABASE"
    su -c - postgres "psql -q -d $DATABASE -f {{ postgis_version.stdout }}"
    su -c - postgres "psql -q -d $DATABASE -c 'grant all on geometry_columns to sahana;'"
    su -c - postgres "psql -q -d $DATABASE -c 'grant all on spatial_ref_sys to sahana;'"
fi
