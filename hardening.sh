#!/bin/bash

echo '************* DNS SERVER HARDENING *************'
echo
echo step1: Updating bind server
echo
yum update bind bind-chroot -y &> /dev/null
if [ $? -eq 0 ]
then
	echo DNS Service Updated successfully
fi

echo Restarting DNS service
systemctl restart named-chroot &> /dev/null
echo
#########################################################################################

echo step2: Hiding BIND VERSION 
conf_file="/etc/named.conf"
echo
value=$( cat $conf_file | egrep "^\sversion" )
if [[ $? -eq 0 ]]
then
	final=$( echo $value | cut -d'"' -f2 )
	if [[ $final == "Access Denied" ]]
	then
		echo Already hidden
	else
		#Substituting a line in a file
		sed -i 's/\(^\sversion "\)[a-z0-9 ]*\(";\)/\1Access Denied\2/i' $conf_file
		
	fi
else
	#Appending version directive after the session-key directive
	echo Adding Version directive in the bind configuration file.
	sed -i '/session-keyfile/a \\tversion "Access Denied";' $conf_file
	if [[ $? -eq 0 ]]
	then
		echo Successfully Hiding Bind Version
		#service named restart
	else
		echo Error ...........
	fi
fi

systemctl restart named-chroot
echo

##############################################################################

echo Step3: Restricting zone transfer

echo 
echo -e "1. Using ACL\t2.via Authenticate Zone Transfer"
read -p "Enter your choice : " choice

if [[ $choice -eq 1 ]]
then
	
	filename='/etc/named.conf'

	read -p "Enter the domain name: " domain
	read -p "Enter the acl name: " aclname
	sed -i "/^options {/i acl $aclname {" $filename
	for i in $( dig -t ns $domain +short )
	do
	        var=$( dig $i +short )
        	sed -i "/acl/a $var;" $filename
	done
	sed -i '/^options/i };' $filename
	sed -i '/^options/i \\n' $filename

	response=$( cat $filename | egrep "allow\-transfer" )
	if [[ $? -eq 0 ]]
	then
        	check=$( echo $response | cut -d'{' -f2 | cut -d' ' -f2 | cut -d';' -f1 )
        	if [[ $check == $aclname ]]
       		then
                	echo ACL ALREADY EXISTED
        	else
                	sed -i "s/^\(\sallow\-transfer { \)[a-zA-Z0-9.;\s]*\( };\)/\1$aclname;\2/" $filename
        	fi
	else
        	sed -i '/^\ssession-key/a \\tallow\-transfer { '"$aclname;"' };' $filename
	fi

	echo Restarting Dns service
	systemctl restart named-chroot

#-------------------------------------------------------------------------------------------------------------------------

elif [[ $choice -eq 2 ]]
then
	
	echo Generating secret-key for ZONE TRANSFER
	cd /etc/named/keys &> /dev/null

	if [[ $? -ne 0 ]]
	then
        	echo Creating /etc/named/keys directory
        	mkdir -p /etc/named/keys
        	chown root.named /etc/named/keys
        	chmod -R 770 /etc/named/keys
        	cd /etc/named/keys &> /dev/null
	fi

#kfile is the file name used to store the key
	read -p "Enter the filename for the key to be stored : " kfile

#creating shared secret key for zone transfer
	dnssec-keygen -a HMAC-MD5 -b 128 -n HOST $kfile &> /dev/null

# Getting the shared secret key
	SECRET_KEY=$( cat /etc/named/keys/K$kfile.*'.private' | grep Key | cut -d' ' -f2 )
#echo $SECRET_KEY

	echo "The secret key for authentication is : $SECRET_KEY"
	echo "Caution : Save this key for further configuration "
	echo
	read -p "Enter the key name : " key_name
	echo "Caution : Please remember the key name "
	filename="/etc/named/tsig.key"
	if [[ -e "/etc/named/tsig.key" ]]
	then
        	sed -i '1 i\key \"'"$key_name"'\" {' $filename          	# If file already exist
                                                                		# "0," in sed is used to apply the actions to first match only
        	sed -i '/'"$key_name"'/a \\talgorithm hmac-md5;' $filename
        	sed -i '0,/algorithm/!b;//a \\tsecret '"$SECRET_KEY"';' $filename
        	sed -i '0,/secret/!b;//a};' $filename
	else
        	touch $filename                    			         	# If file doesn't exist
        	echo "key \"$key_name\" { " >> $filename
        	sed -i '/'"$key_name"'/a \\talgorithm hmac-md5;' $filename
        	sed -i '/algorithm/a \\tsecret \"'"$SECRET_KEY"'\";' $filename
        	sed -i "/secret/a};" $filename
	fi
	
	cat /etc/named.conf | grep 'allow-transfer'
	if [[ $? -ne 0 ]]
	then
        	sed -i '/session-keyfile/a\\tallow-transfer { key \"'"$key_name"'\"; };' /etc/named.conf
	else
        	sed -i 's/\(\sallow-transfer {\).*\(};\)/\1 key \"'"$key_name"'\"; \2/' /etc/named.conf
	fi
	echo "include \"$filename\";" >> /etc/named.conf

#echo "Restarting the Chrooted DNS service"
#systemctl restart named-chroot

	echo "Restarting Dns service"
	systemctl restart named-chroot
	
else
	echo -e "Wrong option Entered ....\nSkipping zone tranfer ..."
fi

##############################################################################

echo Step 4: Resctrict Dns Recursion

file="/etc/named.conf"              # Configuration file

echo
echo -e "1. Deny recursion\t2. Allow recursion"
read choice

out=$( cat $file | egrep "^\srecursion" | cut -d' ' -f2 | cut -d';' -f1 )

if [[ $choice -eq 1 ]]; then
        cat $file | egrep "^\srecursion" &> /dev/null
        if [[ $? -eq 1 ]]; then                                                 # If recursion directive is not present
                sed -i '/^\tsession-key/a \\trecursion no;' $file
        elif [[ $out == yes ]]; then
                sed -i 's/^\srecursion.*/\trecursion no;/' $file                # If recursive directive  present but set as yes
        fi
else
        cat $file | egrep "^\srecursion" &> /dev/null
        if [[ $? -eq 1 ]]; then                                                 # If recursive directive is not present
                 sed -i '/^\tsession-key/a \\trecursion yes;' $file
        elif [[ $out == no ]]; then                                             # Recursive directive is present but set as no
                 sed -i 's/^\srecursion.*/\trecursion yes;/' $file
        fi
fi


if [[ $choice -eq 2 ]];then							# If recursive directive is set to yes
	ips="127.0.0.1"								# Default value for recursive is local machine
	echo -e "1. Enter the network Address  2.Enter ip of host  3. Done"
	read -p "Enter Your choice : " ch
	echo
	while [[ $ch -ne 3 ]];	do
		if [[ $ch -eq 1 ]];then
			read -p "Enter Network address : " net_addr
			ips="$ips $net_addr"
		else
			read -p "Enter Host ip : " ip_addr
			ips="$ips $ip_addr"
		fi
        	echo -e "1. Enter the network Address  2.Enter ip of host  3. Done"
        	read -p "Enter Your choice : " ch
		echo
	done
	
	final=
	for i in $ips;do
		final="$final $i;"
	done
	sed -i '/^\srecursion/a \\tallow-recursion {'"$final"' };' $file	
fi

systemctl restart named-chroot
