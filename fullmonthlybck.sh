#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

bkpdate=`date "+%Y%m%d"`
bkptime=`date "+%H%M%S"`
lastmonthdate=`date "+%Y%m" -d 'last month'`
backupdir=/backup/monthly/thismonth
monthly=/backup/monthly
daily=/backup/daily
mycnf=/etc/mysql/my.cnf
mysqlpasswd=`cat /root/.mysqlpasswd`
log=/backup/log/backup.log

#Moving last week full backup to his original date dir

#Cheking if backup dir exists
if ! [ -d $monthly/$lastmonthdate ]; then
	#Moving last week full backup to his original date dir
	mv $backupdir $monthly/$lastmonthdate
	mv $daily/thismonth $daily/$lastmonthdate	
else
	#If last week full backup dir exists - moving it to temp	
	mv $backupdir $monthly/$bkpdate
	mv $daily/thismonth $daily/$bkpdate
fi

echo "Starting mysql backup $bkpdate $bkptime" >> $log
#Backuping mysql
innobackupex --defaults-file=$mycnf --password=$mysqlpasswd --no-timestamp --rsync $backupdir 2>&1
#Backuping binary log while mysql were backuping
innobackupex --apply-log --redo-only --defaults-file=$mycnf --password=$mysqlpasswd --no-timestamp  --throttle=40 $backupdir 2>&1
echo "Done $bkpdate $bkptime" >> $log
