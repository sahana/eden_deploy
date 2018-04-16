import re

# @ToDo: Support lines for alternate Themes

vserver = """vserver!#!collector!enabled = 1
vserver!#!directory_index = index.html
vserver!#!document_root = /var/www
vserver!#!error_handler = error_redir
vserver!#!error_handler!503!show = 0
vserver!#!error_handler!503!url = /maintenance.html
vserver!#!error_writer!filename = /var/log/cherokee/cherokee.error
vserver!#!error_writer!type = file
vserver!#!logger = combined
vserver!#!logger!access!buffsize = 16384
vserver!#!logger!access!filename = /var/log/cherokee/cherokee.access
vserver!#!logger!access!type = file
vserver!#!match = wildcard
vserver!#!match!domain!1 = *
vserver!#!match!nick = 0
vserver!#!nick = Production
vserver!#!rule!800!handler = redir
vserver!#!rule!800!handler!rewrite!10!regex = /(.*)$
vserver!#!rule!800!handler!rewrite!10!show = 1
vserver!#!rule!800!handler!rewrite!10!substring = https://${host}/$1
vserver!#!rule!800!match = not
vserver!#!rule!800!match!right = tls
vserver!#!rule!700!expiration = epoch
vserver!#!rule!700!expiration!caching = public
vserver!#!rule!700!expiration!caching!must-revalidate = 1
vserver!#!rule!700!expiration!caching!no-store = 0
vserver!#!rule!700!expiration!caching!no-transform = 0
vserver!#!rule!700!expiration!caching!proxy-revalidate = 1
vserver!#!rule!700!handler = common
vserver!#!rule!700!handler!allow_dirlist = 0
vserver!#!rule!700!handler!allow_pathinfo = 0
vserver!#!rule!700!match = fullpath
vserver!#!rule!700!match!fullpath!1 = /maintenance.html
vserver!#!rule!600!document_root = /var/www/.well-known
vserver!#!rule!600!expiration = time
vserver!#!rule!600!expiration!caching = public
vserver!#!rule!600!expiration!caching!must-revalidate = 1
vserver!#!rule!600!expiration!caching!no-store = 0
vserver!#!rule!600!expiration!caching!no-transform = 0
vserver!#!rule!600!expiration!caching!proxy-revalidate = 1
vserver!#!rule!600!expiration!time = 7d
vserver!#!rule!600!handler = file
vserver!#!rule!600!match = directory
vserver!#!rule!600!match!directory = /.well-known
vserver!#!rule!600!match!final = 1
vserver!#!rule!500!document_root = /home/prod/applications/{{ appname }}/static
vserver!#!rule!500!encoder!deflate = allow
vserver!#!rule!500!encoder!gzip = allow
vserver!#!rule!500!expiration = time
vserver!#!rule!500!expiration!time = 7d
vserver!#!rule!500!handler = file
vserver!#!rule!500!match = fullpath
vserver!#!rule!500!match!fullpath!1 = /favicon.ico
vserver!#!rule!500!match!fullpath!2 = /robots.txt
vserver!#!rule!500!match!fullpath!3 = /crossdomain.xml
vserver!#!rule!400!document_root = /home/prod/applications/{{ appname }}/static/img
vserver!#!rule!400!encoder!deflate = forbid
vserver!#!rule!400!encoder!gzip = forbid
vserver!#!rule!400!expiration = time
vserver!#!rule!400!expiration!caching = public
vserver!#!rule!400!expiration!caching!must-revalidate = 0
vserver!#!rule!400!expiration!caching!no-store = 0
vserver!#!rule!400!expiration!caching!no-transform = 0
vserver!#!rule!400!expiration!caching!proxy-revalidate = 0
vserver!#!rule!400!expiration!time = 7d
vserver!#!rule!400!handler = file
vserver!#!rule!400!match = directory
vserver!#!rule!400!match!directory = /{{ appname }}/static/img/
vserver!#!rule!400!match!final = 1
vserver!#!rule!300!document_root = /home/prod/applications/{{ appname }}/static
vserver!#!rule!300!encoder!deflate = allow
vserver!#!rule!300!encoder!gzip = allow
vserver!#!rule!300!expiration = epoch
vserver!#!rule!300!expiration!caching = public
vserver!#!rule!300!expiration!caching!must-revalidate = 1
vserver!#!rule!300!expiration!caching!no-store = 0
vserver!#!rule!300!expiration!caching!no-transform = 0
vserver!#!rule!300!expiration!caching!proxy-revalidate = 1
vserver!#!rule!300!handler = file
vserver!#!rule!300!match = directory
vserver!#!rule!300!match!directory = /{{ appname }}/static/
vserver!#!rule!300!match!final = 1
vserver!#!rule!200!encoder!deflate = allow
vserver!#!rule!200!encoder!gzip = allow
vserver!#!rule!200!handler = uwsgi
vserver!#!rule!200!handler!balancer = round_robin
vserver!#!rule!200!handler!balancer!source!10 =
vserver!#!rule!200!handler!check_file = 0
vserver!#!rule!200!handler!error_handler = 1
vserver!#!rule!200!handler!modifier1 = 0
vserver!#!rule!200!handler!modifier2 = 0
vserver!#!rule!200!handler!pass_req_headers = 1
vserver!#!rule!200!match = directory
vserver!#!rule!200!match!directory = /
vserver!#!rule!100!handler = common
vserver!#!rule!100!handler!iocache = 1
vserver!#!rule!100!match = default
vserver!#!ssl_certificate_file = /etc/cherokee/fullchain.pem
vserver!#!ssl_certificate_key_file = /etc/cherokee/privkey.pem
"""
source = """source!#!env_inherited = 1
source!#!group = web2py
source!#!host = 127.0.0.1:59025
source!#!interpreter = /usr/local/bin/uwsgi -s 127.0.0.1:59025 --ini /home/prod/uwsgi.ini
source!#!nick = uWSGI #
source!#!timeout = 1000
source!#!type = host
source!#!user = web2py
"""


File = open("/etc/cherokee/cherokee.conf", "r")
file = File.readlines()
File.close()

content = ''.join(file)

# Search for last vserver number
try:
    vnumber = re.findall(r"vserver\!([0-9]{2})", content)[-1]
    vserver = vserver.replace("vserver!#", "vserver!%s" % str(int(vnumber) + 10))
except IndexError:
    vserver = vserver.replace("vserver!#", "vserver!30")

# Search for last source number
try:
    snumber = re.findall(r"source\!([0-9]{1})", content)[-1]
    source = source.replace("source!#", "source!%s" % str(int(snumber) + 1))
    source = source.replace("uWSGI #", "uWSGI %s" % str(int(snumber) + 1))
    vserver = vserver.replace("balancer!source!10 =", "balancer!source!10 = %s" % str(int(snumber) + 1))
except IndexError:
    source = source.replace("source!#", "source!1")
    source = source.replace("uWSGI #", "uWSGI 1")
    vserver = vserver.replace("balancer!source!10 =", "balancer!source!10 = 1")

File = open("/etc/cherokee/cherokee.conf", "w")
if "env_inherited" in content:
    for line in file:
        if "source!1!env_inherited" in line:
            File.write(vserver)
        elif "icons!directory" in line:
            File.write(source)
        File.write(line)
else:
    for line in file:
        if "icons!directory" in line:
            File.write(vserver)
            File.write(source)
        File.write(line)

File.close()
