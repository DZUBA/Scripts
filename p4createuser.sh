#!/bin/sh
#List of users that need to be created. Every user typed in format "First Name" "Second Name", for example "Von Miller"
list="$HOME/p4users"

#Reading user list
cat $HOME/p4users | while read newuser;
do
	first=$(echo $newuser | awk '{print $1}' | cut -c1 | tr '[:upper:]' '[:lower:]');
	second=$(echo $newuser | awk '{print $2}' | tr '[:upper:]' '[:lower:]');
	p4user="${first}_${second}"
	echo $p4user >> $HOME/p4/p4logins
	touch $HOME/p4/$p4user
	p4userfile="$HOME/p4/$p4user"
echo "User: $p4user
Email: $p4user@example.org
FullName: $newuser" > $p4userfile;
cat $p4userfile | p4 -p __P4SERVER_IP___:___P4PORT___ -u ____P4ADMINLOGIN____ user -f -i
done
