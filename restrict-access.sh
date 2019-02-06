#!/bin/bash

# Should be run on the public facing dns server

filename='/etc/named.conf'

read -p "Enter the acl name to blacklist private ip: " black_acl
ips='10.0.0.0/8 172.16.0.0/12 192.168.0.0/16'
sed -i '/^options {/i acl \"'"$black_acl"'\" {' $filename
for ip in $ips
do
	echo $ip
	sed -i '/'"$black_acl"'/a \\t'"$ip;" $filename 
done
sed -i '/^options {/i };\n' $filename

sed -i '/^\ssession-keyfile/a \\tblackhole { \"'"$black_acl"'\"; };' $filename
echo Restarting Dns Server
systemctl restart named-chroot &> /dev/null
