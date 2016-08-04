#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/dzuba"

num=2097152
esxihost=$1
volume="vmfs/volumes"
mysqluser="$HOME/creds/.freeipdbuser";
mysqlpassword="$HOME/creds/.freeipdbpasswd";
mysqlhost="___TYPE_HERE_MYSQL_IP___";
mysqldb="devinfo";

vmlist=$(ssh root@$esxihost "vim-cmd vmsvc/getallvms" | awk '{print $2}' | sed '1d')
esxids=$(ssh root@$esxihost "esxcli storage filesystem list" | grep VMFS-5 | awk '{print $2}')
esxihw=$(echo "select id from hwservers where ipaddr = '$esxihost' limit 1"| mysql $mysqldb -u$mysqluser -h$mysqlhost -p$mysqlpassword --skip-secure-auth | sed '1d' )

for ds in $esxids;
do

    for id in $vmlist;
    do
      ip=$( echo $id | cut -c 7- );
      vms=$( echo $id | cut -c 1- );
      $(ssh root@$esxihost "cat /$volume/$ds/$vms/$vms.vmx &>/dev/null")
      stdout=$?
      if [ $stdout -eq 0 ]; then
	  cpu=$(ssh root@$esxihost "cat /$volume/$ds/$vms/$vms.vmx" | grep num | awk '{print $3}' | sed 's/\"//g');
            if [ -z $cpu ]; then 
              cpu=1;
            fi
          mem=$(ssh root@$esxihost "cat /$volume/$ds/$vms/$vms.vmx" | grep memSize | awk '{print $3}' | sed 's/\"//g');
      $(ssh root@$esxihost "ls /$volume/$ds/$vms/${vms}_1.vmdk &>/dev/null") &>/dev/null;
      stdout=$?
        if [ $stdout -eq 1 ]; then
          temp=$(ssh root@$esxihost "cat /$volume/$ds/$vms/$vms.vmdk" | grep RW | awk '{print $2}');
	  hdd=$[$temp/$num]
	  mysql $mysqldb -u$mysqluser -h$mysqlhost -p$mysqlpassword --skip-secure-auth -e "INSERT INTO vmservers SET ipaddr='___STAGINGS_NETWORK____.$ip', fqdn='$vms.example.org', cpu='$cpu', ram='$mem', hdd='$hdd', hypervisor='$esxihw';";
        elif [ $stdout -eq 0 ]; then
          temp=$(ssh root@$esxihost "cat /$volume/$ds/$vms/$vms.vmdk" | grep RW | awk '{print $2}');
	  temphdd=$(ssh root@$esxihost "cat /$volume/$ds/$vms/${vms}_1.vmdk" | grep RW | awk '{print $2}');
	  hdd=$[$temp/$num]
          hddsecond=$[$temphdd/$num]
	  mysql $mysqldb -u$mysqluser -h$mysqlhost -p$mysqlpassword --skip-secure-auth -e "INSERT INTO vmservers SET ipaddr='___STAGINGS_NETWORK____.$ip', fqdn='$vms.example.org', cpu='$cpu', ram='$mem', hdd='$hdd', hdd2='$hddsecond', hypervisor='$esxihw';";
	fi
      else
	continue
      fi
     done
done
