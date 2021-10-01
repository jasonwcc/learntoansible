rol.redhat.com
- 90 days
- 80 hours
- 



### Exam
```
- EX294 --> RHCE 
  performance-based (cli)
  yaml + jinja2
  210 of 300
  3 hours
  every hour to 10 minutes
  exam - remote or testing center 
  usb Camera logitech 
  Rhn ID + password
  IC 
  ask series questions
```

The exam environment
```
- You will be started at workstation (desktop)
- full network connectivity other virtual machines
= Click RedHat icon on activies menu to proceed to system configuration and exam tasks
```

System Configurations:
```
There are 5 virtual machines with root account 
(password : devops)
node1.example.com   172.24.16.6 / 172.25.250.9
node2.example.com   172.24.16.7 / 10
node3.example.com   172.24.16.8 / 11
node4.example.com   172.24.16.9 / 12
node5.example.com   172.24.16.10/ 13
control.example.com 172.24.16.11

SSH is configured in such way that each of this VM can log 
into each other using root without password
There is greg with devops password
Account is created in all nodes including control node. You have to use 
greg account to create all playbook, configuration, and all related files
in /home/greg/ansible directory
All files in ansible must belongs to the user
All roles must be located /home/greg/ansible/roles
```

Prepare control node (incl. test):
```
From workstation login into control node using greg 
account
# ssh greg@172.24.16.11
# pwd
/home/greg/
# mkdir -p ansible
# cd ansible
# vi ansible.cfg
[defaults]
inventory = /home/greg/ansible/inventory
roles_path = /home/greg/ansible/roles:/usr/share/ansible/roles

Try install VIM
dnf -y install vim
vi ~/.vimrc
autocmd FileType setlocal yaml,yml,j2 ts=2 sts=2 sw=2 expandtab

From control node, ssh to each managed nodes 
- test whether it is passwordless

ssh greg@172.24.16.6
Yes
ssh greg@172.24.16.7
Yes

ssh-copy-id greg@172.24.16.6
<password: devops>

Remember: use root account ONLY for troubleshooting
```

Task 1: Configure inventory with following grouping
```
- node1 is a member of dev host group
- node2 is a member of test host group
- node3 and node4 is a member of prod host group
- node5 is a member of balancer host group
- prod group is a child group of webservers
```

Answer:
```
```
Task 2: Install ansible

Answer:
```
sudo yum install -y ansible
```
Verify:
ansible all -m ping
ansible-inventory --graph

Task 3: Adhoc command
```
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
```

Answer:
```
vi /home/greg/ansible/adhoc.sh
chmod +x /home/greg/ansible/adhoc.sh
```

Verify:
```cd /home/greg/ansible
./adhoc.sh
BECOME : devops

ssh root@172.24.16.6
ls /etc/yum.repos.d
dnf list
```


Task 4: Download and Install a Galaxy Roles
```
Create ansible/requirements.txt to download
and install below roles. 
NOTE: Make sure to use name below
- URL	: https://rhgls.realm13.example.com/phpinfo.tar
  Name  : phpinfo
  
- URL	: https://rhgls.realm13.example.com/haproxy.tar
  Name  : balancer
```  
Answer:
```
vi /home/greg/ansible/requirements.txt
- src: https://rhgls.realm13.example.com/phpinfo.tar
  name: phpinfo
- src: https://rhgls.realm13.example.com/haproxy.tar
  name: balancer
  
cd /home/greg/ansible
ansible-galaxy install -r requirements.txt -p roles
cd roles
ls -ltr
```

Task 5: Use RHEL System Role
```
Create ansible/timesync.yml to perform following:
- Use existing NTP Provider
- Use 172.24.16.253 as NTP Server
- Use the iburst parameter
```
Answer:
```
sudo dnf -y install rhel-system-roles 
rpm -ql rhel-system-roles
cd /usr/share/ansible/roles/
ls -ltr

cd /home/greg/ansible
vi timesync.yml
---
- name: Use RHEL System Role
  hosts: all
  become: yes
  
  vars:
    timesync_ntp_servers:
	- hostname: 172.24.16.253
	  iburst: yes
	  
  roles:
  - rhel-system-roles.timesync
...
ansible-playbook timesync.yml

Verify:
 systemctl status chronyd
 chronyc sources -v
```
  
Task 6: Use the galaxy roles
```
Create ansible/role.yml to perform 
following:
- Use balancer galaxy role to configured   
  balancer host group to balance 
  www traffic between webservers's 
  nodes
  
  So that when first curl http://node5  
  
  Welcome to node3.example.com

  Second curl http://node5 it yields following 
  
  Welcome to node4.example.com

- Create ansible/phpinfo.yml to perform following:
  Use phpinfo galaxy role to configure webservers 
  with php runtime
  
  So that when first curl http://node3/phpinfo it will 
  yields following result
  Hello PHPinfo from node3.example.com

  So that when first curl http://node4/phpinfo it will 
  yields following result
  Hello PHPinfo from node4.example.com
```

Answer:
```
vi /home/greg/ansible/role.yml
---
- name: Use balancer role 
  hosts: balancer
  become: yes
  
  tasks:
  - include_role:
    name: balancer
...

vi /home/greg/ansible/phpinfo.yml
---
- name: Use phpinfo role 
  hosts: webservers
  become: true
  
  tasks:
  - include_role:
    name: phpinfo
...	
or if tasks ask to use both roles in single playbook
vi /home/greg/ansible/role.yml
---
- name: Use roles
  hosts: all
  become: true
  
  tasks:
  - include_role:
    name: balancer
	when: inventory_hostname in groups['balancer']
	
  - include_role:
    name: phpinfo
    when: inventory_hostname in groups['webservers']
...
or if tasks ask to use both roles in single playbook
vi /home/greg/ansible/role.yml
---
- name: Use roles
  hosts: balancer
  become: true
  
  tasks:
  - include_role:
    name: balancer

- name: Use roles
  hosts: webservers
  become: true	
  
  tasks:
  - include_role:
    name: phpinfo
...
```

Verify:
```
ansible-playbook role.yml
curl http://node5
node3.example.com
curl http://node5
node4.example.com

curl http://node3/phpinfo
  Hello PHPinfo from node3.example.com
curl http://node4/phpinfo
  Hello PHPinfo from node4.example.com

Task 7: Create Custom Role
Create /home/greg/ansible/roles/apache role
Create /home/greg/ansible/newrole.yml to perform following:
- Use the apache role to 
  - install httpd package into webservers nodes
  - enable firewall service with rules to allow httpd 
    traffic into the webservers nodes
  - Configure index.j2 to populate with following content
    into webservers nodes:
	
	    Welcome to HOSTNAME with IP_ADDRESS
```

Answer:
```
cd /home/greg/ansible/roles
ansible-galaxy role init apache 

vi /home/greg/ansible/roles/apache/tasks/main.yml
---
# ...
- name: Install httpd package 
  dnf:
    name: httpd
	state: present

- firewalld:
    service: http
    immediate: yes
    permanent: yes
    state: enabled

- template:
    src: index.j2
    dest: /var/www/html/index.html
...
vi /home/greg/ansible/roles/apache/templates/index.j2
Welcome to {{ ansible_facts.hostname }} with 
{{ ansible_facts.default_ipv4.address }}	
	
vi 	/home/greg/ansible/newrole.yml
---
- name: Use custom role
  hosts: webservers
  become: true
  
  roles:
  - apache
...
```

Verify


Task 8: Install packages based on hosts
```
Create ansible/packages.yml playbook to
- install mariadb and php packages into dev,test,prod host groups
- install RPM Development Tools group of packages into dev host group
- Update all packages in dev host group to latest version
```

Answer:
```
vi 	ansible/packages.yml
---
- name: Install packages on dev,test,prod
  become: true
  hosts: dev,test,prod

  tasks:
  - dnf: 
      name: "mariadb,php"
	  state: present

- name: Install packages on dev only
  become: true
  hosts: dev

  tasks:
  - dnf: 
      name: "@RPM Development Tools"
	  state: present

  - dnf: 
      name: "*"
	  state: latest
...
```

Verify
```
ansible-playbook /home/greg/ansible/packages.yml
```

Task 9: Secret Vault
```
Create locker.yml with following content
---
dev: imadev
test: imatest
...

Encrypt locker.yml with password "ILoveRedHat" and store
the password in secret.txt
```

Answer:
```
cd /home/greg/ansible
echo "ILoveRedHat" > secret.txt

ansible-vault create \
--vault-password-file=secret.txt \
locker.yml
```

Task 10: Create users and groups
```
Download https://rhgls.realm13.example.com/user_list.txt 
into /home/greg/ansible/ directory
Create /home/greg/ansible/users.yml playbook to run in webservers
host group to
- Use users_list.txt to create user with description developer in dev
  host groups
- Use users_list.txt to create user with description manager  in prod
  host groups
Set user's password based on locker.yml  
- make sure to use sha512 algorithm
- User with developer description will use dev variable as the password
- User with manager description will use test variable as the password
```

Answer:
```
cd /home/greg/ansible
wget https://rhgls.realm13.example.com/user_list.txt 
cat user_list.txt
users:
- name: ali
  description: developer
- name: peter
  description: manager
- name: sandy
  description: developer

vi /home/greg/ansible/users.yml
---
- name: Create users in webservers
  hosts: webservers
  become: true
  
  vars_files:
  - user_list.txt
  - locker.yml
  
  tasks:
  - name: Creating user
    user: 
      name: "{{ item.name }}"
      comment: "{{ item.description }}"
      password: "{{ dev | password_hash('sha512') }}"
	loop: "{{ users }}"
    when: item.description == "developer"
	
   - name: Creating user
     user: 
      name: "{{ item.name }}"
      comment: "{{ item.description }}"
      password: "{{ test | password_hash('sha512') }}"
	loop: "{{ users }}"
    when: item.description == "manager"
...
ansible-playbook --vault-password-file=secret.txt users.yml
```

Verify
```
ssh ali@172.25.250.11
```

Task 11: Collect Data
```
Download from https://rhgls.realm13.example.com/hwrequire.empty
into /root/hwrequire.txt in each managed nodes

Modify /root/hwrequire.txt to have following content
hostname=hostname
Total free mem= total_free_mem 
Total used mem= total_used_mem
Total CPU = Number of Processor cores
sda_disk_space= sda_disk_space
sdb_disk_space= sdb_disk_space
hda_disk_space= hda_disk_space
NOTE: if node doesnt have the hw, display NONE

Create ansible/hwrequire.yml
- collect hw information and store in /root/hwrequire.txt  
```

Answer:
```
cd /home/greg/ansible/
wget https://rhgls.realm13.example.com/hwrequire.empty 
cat hwrequire.empty

vi ansible/hwrequire.yml
---
- name: collect information
  become: true
  hosts: all
  
  tasks:
  - template:
       src: hwrequire.j2
	   dest: /root/hwrequire.txt
...

mv hwrequire.empty  hwrequire.j2
vi hwrequire.j2
hostname={{ ansible_facts.hostname }}
Total free mem= {{ ansible_memfree_mb }}
Total used mem= {{ ansible_memory_mb.real.used }}
Total CPU = {{ ansible_process_cores }}
sda_disk_space= {{ ansible_devices.sda.size | default("NONE") }}
sdb_disk_space= {{ ansible_devices.sdb.size | default("NONE") }}
hda_disk_space= {{ ansible_devices.hda.size | default("NONE") }}
```

Task 12: file module - symbolic link
```
Create webcontent.yml playbook to run in balancer group to perform
following tasks:

- Create /webdev with following information:
  : own by webdev group
  : with permission owner=rwx, group=rwx, other=rx
  : with set group id
- Crewate symbolic link /webdev /var/www/html/webdev
- Configure /var/www/html/webdev/index.html display following content 
     Development
- When curl http://node5/webdev/index.html yields 
     Development
```
Answer
```
vi ansible/webcontent.yml
---
- name: Webcontent
  become: true
  hosts: balancer  

  tasks:
  - name: Create directory
    file: 
	   name: /webdev
	   owner: webdev
	   mode: 2775
	   state: directory
  
  - name: Create symbolic link
    file:
	   src: /webdev
	   dest: /var/www/html/webdev
	   state: link
	   
  - name: Add line
    copy:
	  content: "Development"
	  dest: /var/www/html/webdev/index.html
...
```

Task 13: Rekey vault password
```
Download and extract 
from https://rhgls.realm13.example.com/vaulted.tar into
greg/ansible directory
The vaulted/secret.yml is encrypted with password stored in
vaulted/secret.txt

You are required to create new-secret.txt in vaulted/ containing
new password "secure"

Change the vaulted/secret.yml with the new password
```

Answer:
```
cd greg/ansible
wget  https://rhgls.realm13.example.com/vaulted.tar 
tar -xvf vaulted.tar
cd vaulted
ls -ltr
ansible-vault view --vault-password-file=secret.txt secret.yml
cat secret.txt

vi new-secret.txt
secure

ansible-vault rekey --vault-password-file=secret.txt \
--new-vault-password-file=new-secret.txt \
secret.yml
```

Verify
```
ansible-vault view secret.yml
< enter secure >
```

Task 14: Archiving files
```
Create ansible/backup.yml playbook to 
- archive all files in /home/ali, /home/peter into
/tmp/home.tar.bz2 
Run this playbook on database servers only with following 
conditions:
- /tmp/home.tar.bz2 must be owned by root and with 0644 mode
```
Answer
```
vi ansible/backup.yml
---
- name: Archiving files
  hosts: dbservers
  become: true
  
  tasks:
  - name: Backup ali and peter home directory
    archive:
	  format: bz2
	  owner: root
	  mode: "0644"
	  dest: /tmp/home.tar.bz2
	  path: 
	    - /home/ali
	    - /home/peter
...
```

Verify
```
  ansible-playbook backup.yml
  ssh <ip to the db server>
  ls /tmp/home*
  tar -j -tvf /tmp/home.tar.bz2
```
