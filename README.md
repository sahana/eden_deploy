Using Ansible to deploy Eden
------------------------------

To use these scripts to deploy to Amazon EC2, follow these guidelines:
http://eden.sahanafoundation.org/wiki/InstallationGuidelines/Amazon/Setup

To develop ansible scripts:
1.  Install Ansible
 http://docs.ansible.com/intro_installation.html#installing-the-control-machine
 NB Windows doesn't support Ansible control except using the Linux subsystem:
 https://www.jeffgeerling.com/blog/2017/using-ansible-through-windows-10s-subsystem-linux

2.  Create an EC2 Instance and launch it. From the Web UI, note the public ip, public dns and a part of the private dns (before .ec2.internal)

3.  Create/Update /etc/ansible/hosts with the host information. Example

        <PUBLIC IP OF DB SERVER>
        <PUBLIC IP OF EDEN SERVER>
        <PUBLIC IP OF WEBSERVER SERVER>

4. cd to the repository and create a file, say, deploy.yml. Depending upon your deployment type (3-tier or single tier) copy the contents of either multiple.yml or single.yml from examples directory

5. Update the IPs and variables (refer to variable description below)

6. Finally, run ansible-playbook. `ansible-playbook --private-key=<path_to_key> deploy.yml -u <remote_user>` replacing <remote_user> with your server's remote user and <path_to_key> with path to private key associated with the server

Variable Description
-------------------

The Ansible Playbooks use some variables to deploy Eden. Descriptions of these variables are given below.

**NB: Values of variables should be entered without quotes**

| Variable       | Description |
| -------------  | ------------- |
| password       | Database Password |
| db_ip          | IP of the server hosting the Database |
| db_type        | Type of Database - Either "postgresql" or "mysql" |
| sitename       | URL you want to access Eden from |
| web_server     | Only "cherokee" allowed for now. TODO: Apache |
| template       | Eden template to use |
