#!/bin/bash

#######################################################
# $Name: mysql_physical_fullback.sh
# $Version: v1.0
# $Author: ethan_yang
# $Create Date: 2019-07-16
# $Description: MySQL full_backup all-databases
#######################################################

# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi
# User specific environment and startup programs
PATH=/usr/local/mysql/bin:$PATH:$HOME/bin
export PATH

###################   Declare environment variables  #########
record_log=/mysqldata/backup/
log_name=physical_fullback_record.log

backup_dir=/mysqldata/backup/back_images
metadata_dir=/mysqldata/backup/back_metadata

echo "--------------------Full Backup Starting------------------"  >> $record_log/$log_name
date >> $record_log/$log_name

mysqlbackup --user=root --password=XXXXXX --socket=/mysqldata/tmp/mysql.sock --host=localhost \
--backup-image=$backup_dir/physical_fullback_`date '+%m-%d-%Y'`.mbi \
--backup-dir=$metadata_dir/fullback_info_`date '+%m-%d-%Y'` backup-to-image

date >> $record_log/$log_name
echo "--------------------Full Backup Ended------------------"  >> $record_log/$log_name

###############   delete the physical_images and metadata_infor from 7 days ago  #############
 
images_dir=/mysqldata/backup/back_images
find $images_dir -type f -name "physical_fullback_*.mbi" -mtime +7 -exec rm -rf {} \;

metadata_dir=/mysqldata/backup/back_metadata
find $metadata_dir -type d -name "fullback_info_*" -mtime +7 -exec rm -rf {} \;   
