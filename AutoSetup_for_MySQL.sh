#!/bin/bash
#####MySQL5.7.33数据库自动安装脚本
# Version:      1.0
# Author:       Ethan_Yang
# Date:         2021-04-02
#####
Author=Ethan_Yang
#mysql 安装包的绝对路径,去掉.tar.gz
tarGzPath=/mysqlsoft/
tarGzFile=mysql-5.7.33-linux-glibc2.12-x86_64
#mysql 安装路径
installPath=/mysqlsoft/
data_dir=/mysqldata/

#my.cnf配置文件
mysqlcnf=/home/mysql/my.cnf

#mysql serverid需要设置唯一的id,比如 ip+3位数字
mysqlServerid=250196

#mysql 密码(不可擅自修改)
defaultPwd=Timely_999d

#mysql 端口
mysqlPort=3307

#数据存放路径
data_default=${data_dir}${mysqlPort}

#mysql数据目录
# data_default=${installPath}${mysqlPort}
data_datadir=${data_default}/data
data_binlog=${data_default}/binlog
data_dbdata=${data_default}/dbdata
data_logs=${data_default}/logs
data_tmp=${data_default}/tmp
data_undo=${data_default}/undo
# 校验是否为ROOT用户
CheckRoot()
{
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install"
    exit 1
fi
clear
}
 
#优化文件最大打开数
DependFile()
{

if [ $( cat /etc/security/limits.conf  | grep "mysql" | wc -l )  -lt 1 ] ;then
# the parameters added by LY at 2021/02/20 09:43
echo '# add limits for mysql by' ${Author} 'at '`date '+%m-%d-%Y'`  >> /etc/security/limits.conf

cat >>/etc/security/limits.conf << EOF
* soft nproc 65536
* hard nproc 65536
* soft nofile 65536
* hard nofile 65536
mysql soft nproc 65536
mysql hard nproc 65536
mysql soft nofile 65536
mysql hard nofile 65536
EOF

fi

if [ -e /etc/security/limits.d/20-nproc.conf ];then
if [ $( cat /etc/security/limits.d/20-nproc.conf  | grep "mysql" | wc -l )  -lt 1 ] ;then
cat >>/etc/security/limits.d/20-nproc.conf<<EOF
mysql       soft    nproc     unlimited
EOF

fi
fi

if [ -e /etc/security/limits.d/90-nproc.conf ];then
if [ $( cat /etc/security/limits.d/90-nproc.conf  | grep "mysql" | wc -l )  -lt 1 ] ;then
cat >>/etc/security/limits.d/90-nproc.conf<<EOF
mysql       soft    nproc     unlimited
EOF

fi
fi

if [ -e /etc/sysctl.conf ];then
fs_file=$( cat /proc/sys/fs/file-max)
if [ ${fs_file} -lt 65535 ] ;then
sed -i "s/${fs_file}/65535/g" /etc/sysctl.conf
/usr/sbin/sysctl -p 

fi
fi

echo -e "\e[31m #1.配置基础资源 \e[0m"

}

#拷贝tar.gz包
DecompressionTarGz()
{
if [ ! -e ${tarGzPath}${tarGzFile}.tar.gz  ];then
    echo -e "\e[31m ${tarGzPath}${tarGzFile}.tar.gz  不存在！请检查后重新执行脚本 \e[0m"
    exit 1
fi
#解压并重命名到安装目录
if  [ ! -d ${installPath}${tarGzFile} ] ;then
    mkdir -p ${installPath}
    tar -xvf ${tarGzPath}${tarGzFile}.tar.gz -C ${installPath} &> /dev/null
fi

echo -e "\e[31m #2.软件已解压 \e[0m"

}
#添加组合角色
AddMysqlUser()
{
if [ ! $(id -u "mysql") ]; then
   echo "mysql user is not exists for to created"
   /usr/sbin/groupadd mysql
#   /usr/sbin/useradd -g mysql -r -s /sbin/nologin -M mysql
#   /usr/sbin/useradd -g mysql -r -s /bin/bash -M mysql
/usr/sbin/useradd mysql -g mysql
fi

echo -e "\e[31m #3.mysql启动用户已准备完成 \e[0m"

}

#创建mysql 数据目录
createMysqlFolder()
{
if  [ -d ${data_default} ] ;then
    if [ $(du -s  ${data_default}  |  awk 'NR==1{print $1}') -gt 0 ] ;then
        mv  ${data_default}  ${data_default}"`date +%Y%m%d%H%M`"
    fi
fi

mkdir -p ${data_datadir}
mkdir -p ${data_binlog}
mkdir -p ${data_dbdata}
mkdir -p ${data_logs}
mkdir -p ${data_tmp}
mkdir -p ${data_undo}

#赋予权限
chown -R mysql:mysql ${data_default}
chmod 700 ${data_tmp}

echo -e "\e[31m #4.mysql 数据目录 权限 已准备完成 \e[0m"

}

#创建my.cnf
MakeMyCnf()
{

if  [ -e ${mysqlcnf} ] ;then
    #mv  ${mysqlcnf}  ${mysqlcnf}"`date +%Y%m%d%H%M`"
    rm ${mysqlcnf}
fi

touch ${mysqlcnf}
echo -e "\e[31m #5.mysql cnf文件创建成功 \e[0m"

cat >${mysqlcnf}<<EOF
[mysqld_safe]
user = mysql
nice = 0

[client]                           
socket                             = ${data_datadir}/mysql.sock
port                               = ${mysqlPort}
default-character-set 						 = utf8mb4
prompt                             = "\u@db1 \R:\m:\s [\d]> "
no-auto-rehash

[mysqld]
############# GENERAL #############
skip_ssl
skip-name-resolve
autocommit                         = ON
log_timestamps										 = SYSTEM
character_set_server               = utf8mb4
character_set_connection           = utf8mb4
character_set_filesystem           = utf8mb4
character_set_client               = utf8mb4
character_set_results              = utf8mb4

#collation_server                   = utf8mb4_unicode_ci
log_timestamps                     = SYSTEM
collation_server                   = utf8mb4_general_ci
explicit_defaults_for_timestamp    = ON  
lower_case_table_names             = 1
port                               = ${mysqlPort}
read_only                          = OFF
#transaction_isolation             = READ-COMMITTED
#tx_isolation              				 = REPEATABLE-READ
#从 8.0.3 版本开始，去掉了 tx_isolation 参数，参数名只支持 transaction_isolation
transaction_isolation              = REPEATABLE-READ
open_files_limit                   = 65535
max_connections        = 2000
expire_logs_days                   = 10
default-time_zone                  = '+8:00'
####### CACHES AND LIMITS #########
interactive_timeout                = 600 
lock_wait_timeout                  = 300
max_connect_errors                 = 1000000

table_definition_cache             = 2000
table_open_cache                   = 2000 
table_open_cache_instances         = 8

thread_cache_size                  = 32
thread_stack                       = 256K

tmp_table_size                     = 32M
max_heap_table_size                = 64M

query_cache_size                   = 0
query_cache_type                   = 0

sort_buffer_size                   = 1M
join_buffer_size        = 1M
sort_buffer_size        = 1M
read_rnd_buffer_size        = 2M

innodb_io_capacity            = 1000 
innodb_io_capacity_max       = 2000

max_allowed_packet                 = 1024M
slave_max_allowed_packet           = 1024M
slave_pending_jobs_size_max        = 1024M


############# SAFETY ##############
local_infile                       = OFF
skip_name_resolve                  = ON
sql_mode                           = STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,STRICT_ALL_TABLES

############# LOGGING #############
general_log                        = 0
log_queries_not_using_indexes      = ON
log_slow_admin_statements          = ON
log_warnings                       = 2
long_query_time                    = 1  #1秒慢日志
slow_query_log                     = ON

############# REPLICATION #############

server_id                          = ${mysqlServerid}  #ip+3位数字
binlog_checksum                    = CRC32
binlog_format                      = ROW
binlog_rows_query_log_events       = ON

enforce_gtid_consistency           = ON
gtid_mode                          = ON
log_slave_updates                  = ON

master_info_repository             = TABLE
master_verify_checksum             = ON

max_binlog_size                    = 512M
max_binlog_cache_size              = 1024M   #已修改，原值1024
binlog_cache_size        = 8M

relay_log_info_repository          = TABLE
skip_slave_start                   = ON
slave_net_timeout                  = 10
slave_sql_verify_checksum          = ON

sync_binlog                        = 1
sync_master_info                   = 1
sync_relay_log                     = 1
sync_relay_log_info                = 1

############### PATH ##############
basedir                            = ${installPath}${tarGzFile}

datadir                            = ${data_datadir}
tmpdir                             = ${data_tmp}
socket                             = ${data_datadir}/mysql.sock
pid_file                           = ${data_datadir}/mysql.pid
innodb_data_home_dir               = ${data_dbdata}

log_error                          = ${data_logs}/error.log
general_log_file                   = ${data_logs}/general.log
slow_query_log_file                = ${data_logs}/slow.log

log_bin                            = ${data_binlog}/mysql-bin
log_bin_index                      = ${data_binlog}/mysql-bin.index
relay_log                          = ${data_binlog}/relay-log
relay_log_index                    = ${data_binlog}/relay-log.index

# undo settings
innodb_undo_directory        = ${data_undo}
innodb_undo_log_truncate           = 1 
innodb_max_undo_log_size      = 16M
innodb_undo_tablespaces            = 4


############# INNODB #############
innodb_file_format                 = barracuda
innodb_flush_method                = O_DIRECT

innodb_buffer_pool_size            = 1024M
innodb_buffer_pool_instances       = 4 
innodb_thread_concurrency          = 0

innodb_log_file_size               = 1024M
innodb_log_files_in_group          = 2
innodb_flush_log_at_trx_commit     = 1
innodb_support_xa                  = ON
innodb_strict_mode                 = ON

innodb_data_file_path              = ibdata1:32M;ibdata2:16M:autoextend
innodb_temp_data_file_path         = ibtmp1:1G:autoextend:max:30G
innodb_checksum_algorithm          = strict_crc32
innodb_lock_wait_timeout           = 600

innodb_log_buffer_size             = 8M
innodb_open_files                  = 65535

innodb_page_cleaners               = 1
innodb_lru_scan_depth              = 256
innodb_purge_threads               = 4
innodb_read_io_threads             = 4
innodb_write_io_threads            = 4 

innodb_print_all_deadlocks         = 1

[mysql]
############# CLIENT #############                            
max_allowed_packet                 = 16M
socket                             = ${data_datadir}/mysql.sock
no-auto-rehash

[mysqldump]                        
max_allowed_packet                 = 512M	

EOF

echo -e "\e[31m #5.mysql cnf配置完成，【需要按照实际情况更改】 \e[0m"
}

#初始化数据库
InitDataBase()
{
#cd ${installPath}${tarGzFile}
${installPath}${tarGzFile}/bin/mysqld --defaults-file=${mysqlcnf} --basedir=${installPath}${tarGzFile} --datadir=${data_datadir} --user=mysql --initialize

${installPath}${tarGzFile}/bin/mysqld_safe --defaults-file=${mysqlcnf}  --user=mysql   &

#设置socket的软连接
ln -s ${data_datadir}/mysql.sock /tmp/mysql.sock

#设置环境变量
#echo PATH=$PATH:${installPath}${tarGzFile}/bin >> ~/.bash_profile
#source ~/.bash_profile

echo -e "\e[31m #6. 初始化数据库完成并启动服务. \e[0m"

}

#重置密码
ResetPwd()
{
sleep 10s
#从日志中获取mysql初始密码
pwd=`grep "A temporary password is generated for root@localhost: " ${data_logs}/error.log`
pwd=${pwd##*root@localhost:}
#防止因为初始密码中有特殊字符出错 拼接单引号
pwd=${pwd// /}
echo ${pwd}
${installPath}${tarGzFile}/bin/mysql -uroot -p${pwd} -S ${data_datadir}/mysql.sock --connect-expired-password  -e "alter user 'root'@'localhost' identified by   '${defaultPwd}';"

echo -e "\e[31m #7. 已重置数据库密码。登录方式如下: \e[0m"
echo -e "\e[31m ${installPath}${tarGzFile}/bin/mysql -uroot -p  -S ${data_datadir}/mysql.sock \e[0m"

}
#ResetPwd

main()  
{  
###1.校验是否为ROOT用户
CheckRoot  

###2.优化文件最大打开数
DependFile

###3.拷贝tar.gz包
DecompressionTarGz

###4.添加组合角色
AddMysqlUser

###5.创建mysql 数据目录
createMysqlFolder

###6.创建my.cnf
MakeMyCnf

###7.初始化数据库
InitDataBase

###8.重置密码
ResetPwd

}

main
