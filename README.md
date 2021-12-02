Using Ansible to deploy Eden
------------------------------

1. Install the Operating System (Debian 10 'Buster')
2. Download & run the script:
```
bash user-data.sh
```
 
If you wish to bypass the WebSetup GUI then you can delete the last 2 lines & edit the last line to select the template that you wish to run, to set your site's Public DNS, and the email address used to send mails From:
```
bash bootstrap.sh mytemplate myhostname.mydomain sender@domain
```

Note: Whilst this is a modular system, currently this only supports Debian 10, nginx and PostgreSQL (because this is what is used for 90% of installations).
If you need alternate Operating System, Web server and/or Database then you can try the older scripts here:
* https://github.com/sahana/eden_deploy_manual