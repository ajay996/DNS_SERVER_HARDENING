#!/bin/bash

read -p "Enter the filename for TSIG key configuration : " sfile			# sfile is the slave file name provided by the the admin
read -p "Enter the SECRET key provided by the master : " SKEY				#SKEY is the secret key
mkdir -p /etc/named
sfile_full="/etc/named/$sfile"

if [[ ! -f $sfile_full ]]
then
	read -p "Enter the same key name as specified in the server: " key_name
	echo "key $key_name {" >> $sfile_full						# sfile_full is full path of the slave file
	echo -e "\talgorithm hmac-md5;" >> $sfile_full
	echo -e "\tsecret \"$SKEY\";" >> $sfile_full					# SKEY is the secret key
	echo '};' >> $sfile_full
	echo
	read -p "Enter Master Server ip : " server_ip
	echo "server $server_ip {" >> $sfile_full
	echo -e "\tkeys { $key_name; };" >> $sfile_full
	echo '};' >> $sfile_full
else
	echo "File already exist , please enter another file name "
	exit 1
fi

cat /etc/named.conf | grep 'allow-transfer'
if [[ $? -ne 0 ]]
then
        sed -i '/session-keyfile/a\\tallow-transfer { key \"'"$key_name"'\"; };' /etc/named.conf
else
        sed -i 's/\(\sallow-transfer {\).*\(};\)/\1 key \"'"$key_name"'\"; \2/' /etc/named.conf
fi

echo "include \"$sfile_full\";" >> /etc/named.conf
systemctl restart named-chroot
#systemctl restart named
