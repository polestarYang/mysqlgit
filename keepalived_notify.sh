#!/bin/bash
ifalias=${2:-eth1:1}
echo $ifalias
interface=$(echo $ifalias | awk -F: '{print $1}')
echo $interface
vip=$(ip addr show $interface | grep $ifalias | awk '{print $2}')
echo $vip
#contact='linuxedu@foxmail.com'
contact='root@localhost'
workspace=$(dirname $0)
notify() {
    subject="$ip change to $1"
    body="$ip change to $1 $(date '+%F%H:%M:%S')"
   #echo $body | mail -s "$1transition" $contact
     echo $body >> /var/spool/mail/root
}
case "$1" in
    master)
        notify master
        exit 0
    ;;
    backup)
        #/etc/init.d/keepalived stop 
        notify backup
#        /etc/rc.d/init.d/httpd restart
        exit 0
    ;;
    fault)
        notify fault
        exit 0
    ;;
    *)
        echo 'Usage: $(basename $0){master|backup|fault}'
        exit 1
    ;;
esac

