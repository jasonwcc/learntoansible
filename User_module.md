### Ad-Hoc create user with hash password ß
```
vi adhoc
#!/bin/bash
ansible node2 -u root -k -m user -a 'name=devops password={{ "redhat" | password_hash("sha512") }}
chmod +x adhoc
./adhoc
```

### With playbook
```
vi user.yml
---
- name: Create user using users-list.txt and dynamically assigned hash password
  become: true
  hosts: webservers

  vars:
  - hpass: "{{ 'redhat' | password_hash('sha512') }}"

  vars_files: users-list.txt

  tasks:
  - group:
     name: "{{ item }}"
    loop:
    - test
    - dev

  - user:
     name: "{{ item.name }}"
     group: "{{ item.groupn }}"
     password:  "{{ hpass }}"
    loop: "{{ users }}"
...
```

- Run the playbook
````
ansible-playbook user.yml
```
