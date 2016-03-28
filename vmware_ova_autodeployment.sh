#BEGIN
#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/dzuba"

esxihost=$1
esxids=$2
vmcore=$3
vmram=$4
vmvzspace=$5
ovftool="/usr/lib/vmware-ovftool/ovftool"
image="~/OVA/vm_template.ova"
date=`date "+%Y-%m-%d %H:%M:%S"`
mysqluser="~/creds/.mysqluser";
mysqlpassword="~/creds/.mysqlpasswd";
mysqlhost="___TYPE_HERE_MYSQL_IP___";
mysqldb="freeip_db";
stmysqluser="~/creds/.freeipdbuser";
stmysqlpassword="~/creds/.freeipdbpasswd";
stmysqlhost="___TYPE_HERE_FREEIP_MYSQL_IP___";
stmysqldb="devinfo"
esxihw=$(echo "select id from hwservers where ipaddr = '$esxihost' limit 1"| mysql $stmysqldb -u$stmysqluser -h$stmysqlhost -p$stmysqlpassword --skip-secure-auth | sed '1d' )

#Add sshkey
ssh-add ~/.ssh/id_rsa
#Checking if user asking for the help
if [ $esxihost = "-h" ];
	then
	echo "Alex Dzyubenko's autodeployment script.

	NAME
		ovzhostremote.sh - This script for automatic OVZ master host deployment.

	USAGE
		./ovzhostremote.sh <ESXi IP> <ESXi datastorename> <number of cores> <RAM in mb> </vz disk space>

	PARAMETERS DESCRIPTION
		<ESXi IP - set destination ESXi's IP address. Make sure that destination server have free resources for new OVZ master host!
		<ESXi datastorename> - set ESXi's datastore name.
		<number of cores> - set number of cores for OVZ master host from 1 to 24. If varible is blank - default mu,ber of cores gonna be 4.
		<RAM in mb> - set RAM space for OVZ master host. If varible is blank - default size gonna be 4096 MB.
		</vz disk space> - set /vz disk size. If varible is blank - default size gonna be 20 GB.
		For using this script you should install VMware OVFtool - https://www.vmware.com/support/developer/ovf/ and put right path to ovftool by changing variable \"ovftool\" in the beginning of the script. And put right path to your OVA/OVF image in variable \"image\".
		Also you should start SSH-client on ESXi server.

	EXAMPLE
		./ovzhostremote.sh 10.0.0.102 DATASTORE-01 2 4096 20
">&2
                exit 1;	
fi

##Checking if vmcore vmram vmvzspace are numbers

case $vmcore in
	[0-9]|[0-9][0-4])
	;;
	*)
		if [ ! -z $vmcore ]
			then
			echo "Error! Third, forth and fiveth arguments must a numbers or blank! Use key -h to watch manual."
			exit 1;
		fi
	;;
esac

case $vmram in
	[0-9]|[0-9][0-9]|[0-9][0-9][0-9]|[0-9][0-9][0-9][0-9]|[0-9][0-9][0-9][0-9][0-9])
	;;
	*)
		if [ ! -z $vmram ]
			then
			echo "Error! Third, forth and fiveth arguments must a numbers or blank! Use key -h to watch manual."
			exit 1;
		fi
	;;
esac

case $vmvzspace in
	[0-9]|[0-9][0-9]|[0-9][0-9][0-9])
	;;
	*)
		if [ ! -z $vmvzspace ]
			then
			echo "Error! Third, forth and fiveth arguments must a numbers or blank! Use key -h to watch manual."
			exit 1;
		fi
	;;
esac

#Check if mysql client installed
if ! which mysql >/dev/null 2>&1;
	then
	echo "Installing mysql client"
	yum update >/dev/null 2>&1
	#check internet connection
	yum install -y mc
		if [ "$?" -ne 0 ];
  		then 
    		echo -e "Error! Please check internet connect"
    		exit 1
  		fi
	yum install -y mysql
fi

#Check if ovftool installed
if [ ! -e $ovftool ];
	then
	echo "Error! Ovftool doesn't install please install it or change path to ovftools in variable \"ovftool\""
	exit 1;
fi

#Check if OVA/OVF exists
if [ ! -e $image ];
	then
	echo "Error! Can't find OVA/OVF image or change path to image in variable \"image\""
	exit 1;
fi



#Getting free IP
freeip=$(echo "select ip from freeip where status = 'free' and ip like '%___STAGINGS_NETWORK____%' limit 1"| mysql $mysqldb -u$mysqluser -h$mysqlhost -p$mysqlpassword --skip-secure-auth )
vmip=`echo $freeip | cut -d ' ' -f2`
vm=`echo $vmip | cut -d '.' -f4`

#Approving IP and VM name
echo "Next free ip is - $vmip. VM's name gonna be - vm$vm.";
ping -c 2 $vmip > /dev/null 2>&1
	if [ "$?" -eq "0" ];
		then 
		echo "Sorry, but this $ip address busy. Probably record about this IP doesn't exist in FreeIP DB"
		echo "Do you want to continue? [yes or no]:"
		read ans1;
		case $ans1 in
			yes|Yes|YES|y|Y)
			echo "Type ip address for this host. Use IP from ___STAGINGS_NETWORK____  network:";
			while read vmip; do
			ping -c 2 $vmip > /dev/null 2>&1
					if [ "$?" -eq "0" ]; then
					echo "Sorry, but this $vmip address busy. Probably record about this IP doesn't exist in FreeIP DB"
					echo "Type ip address for this host. Use IP from ___STAGINGS_NETWORK____ network:"
				else
					break
          			fi
					continue
			done
				;;
			no|No|NO|n|N)
				echo "Good Bye!";
				exit 0
				;;
			*)
				echo "Sorry, wrong argument. Bye!"
				exit 1
				;;
			esac
	fi

#Renew vm variable if it has been changed
vm=`echo $vmip | cut -d '.' -f4`

$ovftool -n=ua1-vm$vm -dm=thin -ds=$esxids $image "vi://root@$esxihost"
	if [ "$?" -ne 0 ];
  		then 
   		echo -e "Error! Check Deployment parameters or use key -h to read manual."
   		exit 1
  	fi

#Edit VM's parameters
if [ ! -z $vmcore ]
	then
	`ssh root@$esxihost "sed -i 's/numvcpus = .*/numvcpus = "$vmcore"/g' /vmfs/volumes/$esxids/ua1-vm$vm/ua1-vm$vm.vmx"`
fi
if [ ! -z $vmram ]
	then
	`ssh root@$esxihost "sed -i 's/memSize = .*/memSize = "$vmram"/g' /vmfs/volumes/$esxids/ua1-vm$vm/ua1-vm$vm.vmx"`
fi
if [ ! -z $vmvzspace ]
	then
	`ssh root@$esxihost "vmkfstools -X ${vmvzspace}G /vmfs/volumes/$esxids/ua1-vm$vm/ua1-vm${vm}_1.vmdk"`
fi

#Reload VM's config and starting VM
`ssh root@$esxihost "vim-cmd vmsvc/reload /vmfs/volumes/$esxids/ua1-vm$vm/ua1-vm$vm.vmx; vim-cmd vmsvc/power.on /vmfs/volumes/$esxids/ua1-vm$vm/ua1-vm$vm.vmx"`

#Create DNS record for this server to PowerDNS Api
curl "http://dnsadmin.example.org/api/create/?host=vm$vm&ip=$vmip";
#Reserve ip in FreeIP DB
mysql $mysqldb -u$mysqluser -h$mysqlhost -p$mysqlpassword -e --skip-secure-auth "UPDATE freeip SET hostname='RESERVED!!!', status='RESERVED!!!', creation_date='$date', update_date='' WHERE ip='$vmip';"
#Adding record to st-info.example.org
mysql $stmysqldb -u$stmysqluser -h$stmysqlhost -p$stmysqlpassword -e --skip-secure-auth "INSERT INTO vmservers SET ipaddr='$vmip', fqdn='vm$vm.example.org', cpu='$vmcore', ram='$vmram', hdd='16', hdd2='$vmvzspace', hypervisor='$esxihw';";
sleep 5;
#Network setting setup for VM
while : 
do
	`echo "DEVICE=vzbr0
	ONBOOT=yes
	TYPE=Bridge
	IPADDR=$vmip
	NETMASK=___TYPE_NETMASK___
	GATEWAY=___TYPE_GATEWAY___" | ssh root@___STATIC_TEMPLATE_IP____ "cat > /etc/sysconfig/network-scripts/ifcfg-vzbr0"` 
	error=$?
	if [ "$error" -eq 127 ];
		then
		break
	elif [ "$error" -eq 255 ];
		then
		continue
	else
		break 		
	fi
done
`echo "HOSTNAME=vm$vm.example.org" | ssh root@___STATIC_TEMPLATE_IP____ "cat >> /etc/sysconfig/network; resize2fs /dev/sdb; reboot 1>/dev/null "`
#=====
echo "Deployment finished! VM name is ua1-vm$vm. IP - $vmip."
#=====
exit
