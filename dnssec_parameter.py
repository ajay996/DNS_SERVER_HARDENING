#!/usr/bin/python -tt
import os

with open("/etc/named.conf","rt") as in_file:
	buf = in_file.readlines()
	for line in buf:
		if line == "\tdnssec-enable yes;\n":
			print("dnssec-enable yes option is available")
		if line == "\tdnssec-validation yes;\n":
			print("dnssec-validation yes option is available")
		if line == "\tdnssec-lookaside auto;\n":
			print("dnssec-lookaside auto option is available")

with open("/etc/named.conf","w") as out_file:	
	print("Line that can be added: \n1.dnssec-enable yes; \n2.dnssec-validation yes; \n3.dnssec-lookaside auto; \n4.Nothing to be added")
	choice = input("Please enter your choice")
	switcher = {
		1: "\trecursion yes;\n",
		2: "\tdnssec-enable yes;\n",
		3: "\tdnssec-validation yes;\n",
	}
	a = switcher.get(choice,"nothing")
	if a == "\trecursion yes;\n":
		x = "\tdnssec-enable yes;"
	elif a == "\tdnssec-enable yes;\n":
		x = "\tdnssec-validation yes;\n"
	elif a == "\tdnssec-validation yes;\n":
		x = "\tdnssec-lookaside auto;\n"
	for line in buf:
		if line == a:
			line = line + x
		out_file.write(line)
bash_command = "bash /root/project/dnssec.sh"
os.system(bash_command)
