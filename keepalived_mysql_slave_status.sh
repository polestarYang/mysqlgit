#!/bin/bash
#Desc：用于获取主从同步信息，判断主从是否出现异常，然后提交给zabbix
#Date: 2019-06-06
#by：LY

USER="root"
PASSWD="XXXXXXX"
#NAME=$1
NAME="sql"

function IO {
   # status=`ps -C mysql --no-header |wc -l`
   # if [ $status -eq 0 ];then
   #       echo "mysql"
   #       exit 1
    Slave_IO_Running=`mysql -u $USER -p$PASSWD -e "show slave status\G;" 2> /dev/null |grep Slave_IO_Running |awk '{print $2}'`
    touch /etc/keepalived/test.txt
    if [ "$Slave_IO_Running" == "Yes" ];then
        echo 0
        exit 0 
    else
        echo 1
        exit 1 
    fi
}

function SQL {
    Slave_SQL_Running=`mysql -u $USER -p$PASSWD -e "show slave status\G;" 2> /dev/null |grep Slave_SQL_Running: |awk '{print $2}'`
    if [ $Slave_SQL_Running == "Yes" ];then
        exit 0 
    else
        exit 1 
    fi

}


case $NAME in
   io)
       IO
   ;;
   sql)
       SQL
   ;;
   *)
        echo -e "Usage: $0 [io | sql]"
esac
