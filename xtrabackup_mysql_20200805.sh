#######################################################
# $Name: xtrabackup_mysql_20200805.sh
# $Version: v1.0
# $Author: Ethan_Yang
# $Create Date: 2020-08-05
# $Description: Using xtrabackup script to backup MySQL physically in full and incre format 
#######################################################

#xtrabackup自动全备份脚本,具有主从判断功能.
##set environment##
#!/bin/sh
. ~/.bash_profile
WORKPATH="/data/bak"
INNOBACKUPEX="/usr/bin/innobackupex"
MYSQL="/usr/local/mysql/bin/mysql"
BACKUP_USER="root"
BACKUP_PASSWD="root123"
BACKUP_HOST="192.168.0.110"
BACKUP_PORT="3306"
DEFAULTS_FILE="/etc/my.cnf"
SOCKET="/tmp/mysql.sock"
TMPDIR="mysql_173_bak"`date '+%Y%m%d'`
ALL_DATABASES="all"


# Step 1: if slave status is ok,then backup the databases,else send error information and exit
$MYSQL -u$BACKUP_USER -h$BACKUP_HOST  -p$BACKUP_PASSWD -Bse"show slave status \G">${WORKPATH}/slave_status.txt
SLAVE_IO_RUNNING_STATUS=`cat ${WORKPATH}/slave_status.txt|grep Slave_IO_Running|cut -d: -f2|sed s/[[:space:]]//g`
SLAVE_SQL_RUNNING_STATUS=`cat ${WORKPATH}/slave_status.txt|grep Slave_SQL_Running:|cut -d: -f2|sed s/[[:space:]]//g`


if [[ ${SLAVE_IO_RUNNING_STATUS} != Yes ]]; then 
echo "SLAVE_IO_RUNNING_STATUS is not Yes"
exit 0
fi
echo "SLAVE_IO_RUNNING_STATUS is Yes"


if [[ ${SLAVE_SQL_RUNNING_STATUS} != Yes ]]; then 
echo "SLAVE_SQL_RUNNING_STATUS is not Yes"
exit 0
fi
echo "SLAVE_SQL_RUNNING_STATUS is Yes"

##Step 3:rm dmp file before 1 copys
cd $WORKPATH/
keepday=`ls -l|grep mysql_173_bak|wc -l`
if [ $keepday -ge 1 ]
then
 rm -fr `ls -lt|grep mysql_173_bak|awk '{print $9}'`
fi


##Step 4:make  dir
cd $WORKPATH/
if [ ! -f  ${TMPDIR} ]
then
mkdir ${TMPDIR}
fi


#Step 5:to backup
cd $TMPDIR
${INNOBACKUPEX} --defaults-file=${DEFAULTS_FILE} --user=${BACKUP_USER} --password=${BACKUP_PASSWD} --host=${BACKUP_HOST} --socket=${SOCKET} --no-timestamp --parallel=4 $WORKPATH/${TMPDIR}

echo `date '+%Y%m%d%H%M'` 
echo "Today backup success! " 
echo `hostname`" for databases:"${ALL_DATABASES} 
echo "Database's IP is ${BACKUP_HOST}"
exit 0
