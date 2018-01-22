# -*- coding: utf-8 -*-
#
# Python script to fix legacy PostgreSQL databases for migrating web2py-2.14.6=>2.16.1
#
# Procedure:
# - copy fieldnames.py to the web2py folder
# - bash upgrade_web2py.sh
#
try:
    QUOTE_TEMPLATE = db._adapter.__class__.QUOTE_TEMPLATE
except AttributeError:
    raise RuntimeError("Unsupported PyDAL version")

dbtype = settings.db_params["type"]

s3db.load_all_models()

if dbtype == "postgres":
    template = "ALTER TABLE %s RENAME COLUMN %s TO %s;"
else:
    raise RuntimeError("Not a PostgreSQL database")

sql = []

for table in db:
    for field in table:
        fieldname = field.name
        if fieldname != fieldname.lower():
            sql.append(template % (table.sqlsafe,
                                   fieldname.lower(),
                                   QUOTE_TEMPLATE % fieldname,
                                   ))

for statement in sql:
    db.executesql(statement)

db.commit()

