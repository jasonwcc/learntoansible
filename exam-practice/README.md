System Configurations:
There are 5 virtual machines with root account (password : devops). 
node1.example.com	172.24.16.6
node2.example.com	172.24.16.7
node3.example.com	172.24.16.8
node4.example.com	172.24.16.9
node5.example.com	172.24.16.10
control.example.com	172.24.16.11

SSH is configured in such way that each node can log into each other using root without password. 
Account is created in all nodes including the control node. You have to use  account to create all playbook, configuration, and all related files in /home/greg/ansible directory
All files in the ansible must belongs to  user
All roles must be located at /home/greg/ansible/roles

Task : Configure inventory file with following grouping

	- node1 is a member of dbservers host group
	- node2 is a member of test and dev host group
	- node3 and node4 is a member of prod host group
	- node5 is a member of balancer host group
	- webservers group is a child group of prod

Answer:	
vi /home/greg/ansible/inventory
node1	ansible_host=172.24.16.6
node2	ansible_host=172.24.16.7
node3 	ansible_host=172.24.16.8
node4 	ansible_host=172.24.16.9
node5 	ansible_host=172.24.16.10

[dbservers]
node1

[test]
node2

[dev]
node2

[prod]
node3
node4

[balancer]
node5

[webservers:children]
prod
End of Answer	

Task : Install ansible into control node
Answer:	
	dnf -y install ansible

Task : Adhoc command
As System Admin, you need to configure yum repository into each managed nodes. 

Create /home//ansible/adhoc.sh to install 2 repos into each managed nodes

Repository 1: 
	Name: EX294-BASE
	Description: EX294 base software
	BaseURL	: https://rhgls.realm13.example.com/BaseOS/
	GPG Check : Yes
	GPG Key : https://rhgls.realm13.example.com/keys/redhat-release
	Must be enabled

Repository 2: 
	Name: EX294-STREAM
	Description: EX294 stream software
	BaseURL	: https://rhgls.realm13.example.com/AppStream/
	GPG Check : Yes
	GPG Key : https://rhgls.realm13.example.com/keys/redhat-release
	Must be enabled


Answer:	
vi /home/ansible/adhoc.sh
#!/bin/bash
ansible all -m yum_repository -a 'baseurl=https://rhgls.realm13.example.com/BaseOS/ description="EX294 base software" name=EX294-BASE gpgcheck=yes gpgkey=https://rhgls.realm13.example.com/keys/redhat-release enabled=yes'
ansible all -m yum_repository -a 'baseurl=https://rhgls.realm13.example.com/AppStream/ description="EX294 stream software" name=EX294-STREAM gpgcheck=yes gpgkey=https://rhgls.realm13.example.com/keys/redhat-release enabled=yes'

chmod +x /home/ansible/adhoc.sh

Verify
- Go managed hosts, and verify /etc/yum.repos.d/EX294-*.repo exists with correct content

End of Answer	

Task : Install and download galaxy role using requirements.yml
Create /home/greg/ansible/requirements.yml to download and install below roles. Make sure to use name below
	- 	URL	: https://rhgls.realm13.example.com/phpinfo.tar
		Name	: phpinfo

	- 	URL	: https://rhgls.realm13.example.com/haproxy.tar
		Name	: balancer

Answer:	
vi /home/greg/ansible/requirements.txt
- src: https://rhgls.realm13.example.com/phpinfo.tar
   name: phpinfo
- src: https://rhgls.realm13.example.com/haproxy.tar
   name: balancer

cd /home/greg/ansible
ansible-galaxy install -r requirements -p roles
End of Answer	

Task : Use RHEL System Role
Create /home/greg/ansible/timesync.yml to perform following:
	- Use existing NTP Provider
	- Use 172.24.16.253 as the NTP server
	- Use iburst parameter

Answer:	
ON control node, login as root (password should be given)
dnf -y instal rhel-system-roles
rpm -ql rhel-system-roles
NOTE: Look for the path, and copy this path into ansible.cfg
vi /home/greg/ansible/ansible.cfg
roles_path = /home/greg/ansible/:/usr/share/ansible/roles
cd /usr/share/ansible/roles/rhel-system-roles.timesync/README.md 
cp tests/tests_ntp.yml ~/ansible/timesync.yml
vi ~/ansible/timesync.yml
- name: Configure time synchronization with NTP servers
  hosts: all
  vars:
    timesync_ntp_servers:
      - hostname: 172.24.16.253
        iburst: yes
  roles:
    - rhel-system-roles.timesync

ansible-playbook timesync.yml

Verify managed hosts is configured with respective ntp service
systemctl status chronyd

End of Answer	
	
Task : Use the galaxy role
Create /home/greg/ansible/role.yml to perform following:
	Use balancer galaxy role 
	- configure balancer host group to balance www traffic between webservers's nodes

	So that when first curl http://node5 it yields following result
	Welcome to node3.example.com 
	Second curl http://node5 it yields following result
	Welcome to node4.example.com 

Create /home/greg/ansible/phpinfo.yml to perform following:
	Use phpinfo galaxy role 
	- configure webservers with php runtime

 	So that when first curl http://node3/phpinfo it yields following result
	Hello PHPinfo from node3.example.com
 	So that when first curl http://node4/phpinfo it yields following result
	Hello PHPinfo from node4.example.com

Answer:	
vi /home/greg/ansible/role.yml
--- 
- name: Use role
  hosts: all
  become: yes

  tasks:
  - include_role: 
    name: balancer
    when: inventory_hostname in groups['balancer']

  - include_role: 
    name: phpinfo
    when: inventory_hostname in groups['webservers']

End of Answer	

Task : Create custom Role
Create /home/greg/ansible/role/apache role
Create /home/greg/ansible/newrole.yml to perform following:
- Use the apache role to 
: install httpd package into webservers nodes
: Enable firewall service with rules to allow httpd traffic into webservers nodes
: Configure index.j2 to populate with the following content into webservers nodes
			
	Welcome to HOSTNAME with IP_ADDRESS

Answer:	
cd /home/greg/ansible
ansible-galaxy role init apache --init-path roles
vi roles/apache/tasks/main.yml
---
# tasks file for apache
- name: Install apache package
  dnf:
    name: httpd
    state: present

  firewalld:
     immediate: yes
    permanent: yes
    state: enabled
    service: http
#  when: "{{ inventory_hostname}} in groupnames['webservers']"

  template:
    src: index.j2
    dest: /var/www/html/index.html
...

vi roles/apache/templates/index.j2
Welcome to {{ ansible_facts.fqdn }} with {{ ansible_facts.default_ipv4.address }}

vi newrole.yml
---
- name: Run apache role
  hosts: webservers

  roles:
  - apache
...

Verify
curl http://172.24.16.8
curl http://172.24.16.9

End of Answer	

Task : Install packages based on host
Create /home/greg/ansible/packages.yml playbook to 
	- Install mariadb and php packages into dev,test,prod groups
	- Install RPM Development Tools group of packages into dev group
	- Update all packages in dev group to latest version 

Answer:	
vi /home/greg/ansible/packages.yml 
---
- name: Install pacakges based on hosts
  hosts: dev,test,prod

  tasks:
  - dnf:
      name: mariadb,php
      state: present

- name: Install packages into dev group
  hosts: dev

  tasks:
  - dnf:
      name: "@RPM Development Tools"
      state: present

  - dnf:
      name: "*"
      state: latest
...

ansible-playbook /home/greg/ansible/packages.yml

Verify
ssh <node> dnf group list --installed



End of answer	

Task : Secret Vault
Create /home/corona/ansible/locker.yml with following content
---
dev: imadev
test: imatest
...

Encrypt locker.yml with password - ILoveRedHat and store the password in /home/corona/ansible/files/secret.txt


Answer:	
mkdir -p /home/corona/ansible/files
echo ILoveRedHat > /home/corona/ansible/files/secret.txt
ansible-vault create --vault-password-file /home/corona/ansible/files/secret.txt locker-yml
---
dev: imadev
test: imatest
...

Verify
ansible-vault view locker.yml
< ILoveRedHat  >
ansible-vault view --vault-password-file files/secret.txt locker.yml

End of answer	

Task : Create users and groups
Download https://rhgls.realm13.example.com/users_list.txt into greg/ansible directory
Create /home/greg/ansible/users.yml playbook to run in webservers group to
- Use users_list.txt with respective information to:
	Create user with description developer in dev and prod host groups
	Make sure the users is member of devops supplementary group
	Create user with description manager in prod host groups
	Make sure the users is member of opsmgr supplementary group

- Set user's password based on locker.yml
	Make sure to use sha512 algorithm
	User with developer description will use dev variable as the password
	User from manager description will use test variable as the password

Answer:	
cd /home/greg/ansible/
wget https://rhgls.realm13.example.com/users_list.txt
cat users_list.txt
users:
 - name: ali
   description: developer
 - name: peter 
   description: manager
 - name: sandy
   description: developer

vi groups_list.txt
groupn:
- developer
- manager
- devops
- opsmgr

vi /home/greg/ansible/users.yml
---
- name: Create users and groups in webservers
  hosts: webservers

  vars_files:
  - vars/users_list.txt
  - locker.yml

  tasks:
  - group:
      name: "{{ item }}"
      state: present
    loop: "{{ groupn }}"

  - user:
      name: "{{ item.name }}"
      comment: "{{ item.description }}"
      group: "{{ item.description }}"
      groups: devops
      state: present
      password: "{{ dev | password_hash('sha512') }}"
    loop: "{{ users }}"
    when: item.description == "developer"

  - user:
      name: "{{ item.name }}"
      comment: "{{ item.description }}"
      group: "{{ item.description }}"
      groups: opsmgr
      state: present
      password: "{{ test | password_hash('sha512') }}"
    loop: "{{ users }}"
    when: item.description == "manager"
...

 ansible-playbook --vault-password-file vars/secret.txt users.yml

Verify
	ssh ali@servera
	< enter imadev >
	ssh ali@serverb
	< enter imadev >
	ssh peter@serverb
	< enter imatest >

End of answer	

