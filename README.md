Using Ansible to deploy Eden
------------------------------

1. Install the Operating System (Debian 10 'Buster' is preferred)
2. Download & run the script:
```
bash user-data.sh
```
 
If you wish to bypass the WebSetup GUI then you can delete the last 2 lines & edit the last line to select the template that you wish to run, to set your site's Public DNS, and the email address used to send mails From:
```
bash bootstrap.sh mytemplate myhostname.mydomain sender@domain
```
