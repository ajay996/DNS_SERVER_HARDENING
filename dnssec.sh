#!/bin/bash

systemctl restart named-chroot
cd /etc/named/dnssec-key
dnssec-keygen -a RSASHA256 -b 1024 -n ZONE example.com
dnssec-keygen -a RSASHA256 -b 1024 -n ZONE -f KSK example.com
cat Kexample.com.+*.key >> /etc/named/zones/forward.example.com
cat Kexample.com.+*.key >> /etc/named/zones/reverse.example.com
systemctl restart named-chroot
dnssec-signzone -t -g -o example.com /etc/named/zones/forward.example.com /etc/named/dnssec-keys/Kexample.com.*.private 
sed -i 's/\(\sfile "\)\(.*forward.*\)\(";\)/\1\2\.signed\3/' /etc/named/named.conf.local
systemctl restart named-chroot
