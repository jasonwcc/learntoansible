#!/bin/bash
ansible all -m yum_repository -a 'baseurl=https://rhgls.realm13.example.com/BaseOS/ description="EX294 base software" name=EX294-BASE gpgcheck=yes gpgkey=https://rhgls.realm13.example.com/keys/redhat-release enabled=no'
ansible all -m yum_repository -a 'baseurl=https://rhgls.realm13.example.com/AppStream/ description="EX294 stream software" name=EX294-STREAM gpgcheck=yes gpgkey=https://rhgls.realm13.example.com/keys/redhat-release enabled=no'
