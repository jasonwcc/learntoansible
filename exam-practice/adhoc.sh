#!/bin/bash
ansible all -m yum_repository -a 'name=EX294-BASE description="EX294 base software" baseurl=https://rh1.example.com/BaseOS/ gpgcheck=yes gpgkey=https://rh1.example.com/keys/redhat-release enabled=yes'
ansible all -m yum_repository -a 'name=EX294-STREAM description="EX294 stream software" baseurl=https://rh1.example.com/AppStream/ gpgcheck=yes gpgkey=https://rh1.example.com/keys/redhat-release enabled=yes'
