#!/usr/bin/python -tt
import os

x = raw_input("Please enter the channel name")
file_name = raw_input("Please enter the file name you want to store logs")
level = raw_input("Please enter the severity level")
file_location = "/var/named/chroot/var/log/"+file_name
p1 = "\tchannel " + x + " {\n"
p2 = "\t\tfile " + "\"" + file_location + "\"" + ";\n"
p3 = "\t\tprint-time yes;\n"
p4 = "\t\tprint-severity yes;\n"
p5 = "\t\tseverity " + level + ";\n"
p6 = "\t};\n"
c1 = "category notify { " + x  + "; default_debug; };"
c2 = "category xfer-in { " + x + "; default_debug; };"
c3 = "category xfer-out { " + x + "; default_debug; };"
c4 = "category resolver { " + x + "; default_debug; };"
c5 = "category queries { " + x + "; };"
c6 = "category lame-servers { " + x + "; default_debug; };"
with open("/etc/named.conf","rt") as in_file:
	buf = in_file.readlines()
with open("/etc/named.conf","w") as out_file:
	for line in buf:
		if line == "logging {\n":
			print("Logging options available: \n1.Zone Transfer \n2.Recurrsive Query \n3.General Query")
			choice = input("Please enter your choice")
			switcher = {
				1: "\t"+c1+"\n\t"+c2+"\n\t"+c3+"\n",
				2: "\t"+c4+"\n"+"\t"+c6+"\n",
				3: "\t"+c5+"\n",
			}
			a = switcher.get(choice,"nothing")
			line = line+p1+p2+p3+p4+p5+p6+a
		out_file.write(line)
	
os.system("systemctl restart named-chroot")
