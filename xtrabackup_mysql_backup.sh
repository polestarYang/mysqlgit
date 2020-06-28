#######################################################
# $Name: xtrabackup_mysql_backup.sh
# $Version: v1.0
# $Author: Ethan_Yang
# $Create Date: 2020-06-28
# $Description: Using xtrabackup script to backup MySQL physically in full and incre format 
#######################################################

#!/bin/bash
###############################################
# 1. 该备份脚本需要加入到cron中，每天自动执行该脚本
# 2. 以周为单位，进行一次全备，比如周六凌晨
# 3. 然后一周中其他备份时间执行增量备份
###############################################
##
## Filename : xtrabackup_mysql_backup.sh
## Date     : 2017-12-11
## Author   : sunml@xtrabackup.com.cn
## Desc     : backup xtrabackup mysql database
##

## 备份策略:
##              周日(7)： 全备
##     周一 ~ 周六(1-6)： 增量备份

source /etc/profile
ulimit -HSn 102400 

##
## ========== global var ============
##

# 如果一台服务器上有多个MySQL，可以使用 BAK_DIR_ROOT进行备份路径的区别
# 可增加端口作为区分，例如 /opt/backup/mysqk/3306
BAK_DIR_ROOT="/opt/backup/mysql"
# 默认周日进行全备 (1 - 7), 1 是周一，7是周日
FULL_BAK_DAY_OF_WEEK=7 
# 备份文件保留周期，默认保留35天 (4-5周)
HOLD_DAYS=14

MYSQL_USERNAME="xtrabackup_backup"
MYSQL_PASSWORD="Infra5@Gep0int"

MYSQL_CNF="/etc/my.cnf"
MYSQL_MULTI_GROUP="--socket=/tmp/mysql.sock"
# 如果使用多实例，比如通过ecloud的方式下发安装，默认使用多实例
#MYSQL_MULTI_GROUP="--defaults-group=mysqld3307 --socket=/tmp/mysql3307.sock"

CURRENT_WEEK_OF_YEAR=$(date +%U)
CURRENT_DAY_OF_WEEK=$(date +%u)
CURRENT_DATE=$(date +%F)
CURRENT_TIME=$(date +%H-%M-%S)
CURRENT_DATETIME="${CURRENT_DATE}_${CURRENT_TIME}"

BAK_WEEK_DIR="${BAK_DIR_ROOT}/WEEK_${CURRENT_WEEK_OF_YEAR}"

BAK_FULL_DIR="${BAK_WEEK_DIR}/FULL"

BAK_LOG="${BAK_WEEK_DIR}/backup.log"



##
## ========== function =============
##

function clean_backup() {
    find ${BAK_DIR_ROOT}  -mtime +${HOLD_DAYS}  -prune -exec rm -rf {} \;
}


function write_start_log() {

    if [[ ! -d ${BAK_WEEK_DIR} ]];then
        mkdir -p ${BAK_WEEK_DIR}
    fi

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${CURRENT_DATETIME} Begin Backup <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> ${BAK_LOG}

}

function full_backup() {

    if [[ ! -d ${BAK_FULL_DIR} ]]; then
        mkdir -p ${BAK_FULL_DIR}
    fi

    echo "*** FULL BACKUP Date : ${CURRENT_DATETIME}" >> ${BAK_FULL_DIR}/full_backup.date

    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --no-timestamp --user=${MYSQL_USERNAME} --password=${MYSQL_PASSWORD} --compress --compress-threads=4 --stream=xbstream --parallel=4 --extra-lsndir="${BAK_FULL_DIR}/LSN_INFO"  ${BAK_FULL_DIR}  > "${BAK_FULL_DIR}/mysql_backup_full.xbstream"  2>> ${BAK_LOG}

}


# 每周周一到周六进行增量备份
function incr_backup() {

    CURRENT_INCR_DIR="${BAK_WEEK_DIR}/INCR_${CURRENT_DAY_OF_WEEK}"
    PREV_DAY_OF_WEEK=$((${CURRENT_DAY_OF_WEEK} - 1))
    BASE_DIR="${BAK_WEEK_DIR}/INCR_${PREV_DAY_OF_WEEK}"

    # 如果不存在之前的增量，则使用全量路径作为增量的BASE
    # 比如周一的时候
    if [[ ! -d ${BASE_DIR} ]];then
        BASE_DIR=${BAK_FULL_DIR}
    fi

    # 如果在此函数中，还没有BASE，则认为可能是在项目第一周执行
    # 进行一次全量备份
    if [[  ! -d ${BASE_DIR} ]];then
        echo "*** ${BASE_DIR} as BASE_DIR is not exists!" >> ${BAK_LOG}
        echo "***  So Backup Processor into FULL BACKUP " >> ${BAK_LOG}
        full_backup
        exit $?
    fi

    # 如果存放增量数据的目录已经存在，这里进行添加时间戳处理（一天备份多次）
    if [[ -d ${CURRENT_INCR_DIR} ]];then
        CURRENT_INCR_DIR="${CURRENT_INCR_DIR}_${CURRENT_DATETIME}"
    fi

    # 如果BASE_DIR 存在，则进行增量备份
    if [[ ! -d ${CURRENT_INCR_DIR} ]];then
        mkdir -p ${CURRENT_INCR_DIR}
    fi

    echo "*** INCR BACKUP Date : ${CURRENT_DATETIME}" >> ${CURRENT_INCR_DIR}/incr_backup.date

    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --no-timestamp --user=${MYSQL_USERNAME} --password=${MYSQL_PASSWORD} --compress --compress-threads=4 --stream=xbstream --parallel=4 --incremental --incremental-basedir="${BASE_DIR}/LSN_INFO" --extra-lsndir="${CURRENT_INCR_DIR}/LSN_INFO"  ${CURRENT_INCR_DIR}  > "${CURRENT_INCR_DIR}/mysql_backup_incr_${CURRENT_DAY_OF_WEEK}.xbstream" 2>> ${BAK_LOG}

}


#################  main #################

write_start_log

# 如果指定的全备时间 == 当前的时间，则执行全备
if [[ ${FULL_BAK_DAY_OF_WEEK} -eq ${CURRENT_DAY_OF_WEEK} ]];then
    full_backup
    exit $?
fi


# 其他则进行增量备份，如果增量备份发现没有BASE
# 则进行全量备份
incr_backup


clean_backup

