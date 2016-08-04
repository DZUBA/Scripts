#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

bkpdate=$(date "+%Y%m%d")
bkptime=$(date "+%H%M%S")
backupdir=/backup/montly/thismonth
daily=/backup/daily/thismonth
mycnf=/etc/mysql/my.cnf
mysqlpasswd=$(cat $HOME/.mysqlpasswd)
log=/backup/log/backup.log

echo "Starting mysql backup $bkpdate $bkptime" >> $log
#Backuping mysql
innobackupex --defaults-file=$mycnf --password=$mysqlpasswd --no-timestamp  --throttle=40  --rsync --incremental $daily/$bkpdate --incremental-basedir=$backupdir 2>&1
#Backuping binary log while mysql were backuping
innobackupex --defaults-file=$mycnf --password=$mysqlpasswd --no-timestamp  --throttle=40 --apply-log $backupdir --incremental-dir=$daily/$bkpdate 2>&1
echo "Done $bkpdate $bkptime" >> $log
