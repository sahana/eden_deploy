import hashlib
(db_string, pool_size) = settings.get_database_string()
prod_table_string = hashlib.md5(db_string).hexdigest()
settings.database.database = "sahana-test"
(db_string, pool_size) = settings.get_database_string()
test_table_string = hashlib.md5(db_string).hexdigest()
File = open("/usr/local/bin/clean_eden", "r")
file = File.readlines()
File.close()
File = open("/usr/local/bin/clean_eden", "w")
for line in file:
    if "TABLE_STRING" in line:
        line = line.replace("PROD_TABLE_STRING", prod_table_string).replace("TEST_TABLE_STRING", test_table_string)
    File.write(line)
File.close()
