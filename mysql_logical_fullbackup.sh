#######################################################
# $Name: mysql_logical_fullback.sh
# $Version: v1.0
# $Author: ethan_yang
# $Create Date: 2019-07-16
# $Description: MySQL full_backup all-databases
#######################################################

#!bin/bash
PATH=$PATH:$HOME/bin

export PATH=/mysqlsoft/mysql/bin:$PATH

backup_dir=/mysqldata/backup
backup_log=full_backup_dcm.log

echo "--------------------Full Backup Starting------------------"  >> $backup_dir/$backup_log 
date >> $backup_dir/$backup_log

/mysqlsoft/mysql/bin/mysqldump -u root -pAirchina_869 --single-transaction --master-data=2 --all-databases -E -R --triggers --set-gtid-purged=o
ff --socket=/tmp/mysql.sock > $backup_dir/logigal_fullDB_`date '+%m-%d-%Y'`.sql

echo "--------------------Full Backup Ended------------------"  >> $backup_dir/$backup_log
date >> $backup_dir/$backup_log

backup_log=/mysqldata/backup
find $backup_log -type f -name "logigal_fullDB_*.sql" -mtime +7 -exec rm -rf {} \;
/
