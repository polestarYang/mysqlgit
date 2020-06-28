#######################################################
# $Name: xtrabackup_mysql_backup.sh
# $Version: v1.0
# $Author: Ethan_Yang
# $Create Date: 2020-06-28
# $Description: Using xtrabackup script to recover MySQL physically in full and incre format 
#######################################################


#!/bin/bash
##
## Filename : xtrabackup_mysql_recover.sh
## Date     : 2017-12-12
## Author   : sunml@xtrabackup.com.cn
## Desc     : recover xtrabackup mysql database
##

# 恢复脚本，注意:该脚本仅适用于 xtrabackup_mysql_backup.sh 备份出来的
#                一周为单位存储的文件夹，其他自定义备份不适用
#                另外，对于某天多次备份的脚本（生成了 inc_x_20xx-yy-zz_hh-mm-ss） 的文件夹会忽略

# 针对执行该脚本的主机，也需要有percona-xtrabackup和qpress的安装（建议直接装公司的bin文件）

source /etc/profile

##
## ========== global var ============
##

WEEK_DIR=""
TO_DIR=""

MYSQL_USERNAME="xtrabackup_backup"
MYSQL_PASSWORD="Infra5@Gep0int"

MYSQL_CNF="/etc/my.cnf"

#
## 如果是多实例，请开启下面的参数，并修改正确的值
#
MYSQL_MULTI_GROUP="--defaults-group=mysqld3307"

#----------------------------------------------

CURRENT_DATE=$(date +%F)
CURRENT_TIME=$(date +%H-%M-%S)
CURRENT_DATETIME="${CURRENT_DATE}_${CURRENT_TIME}"

RECOVER_LOG="./recover_${CURRENT_DATETIME}.log"

INCR_DIRS=('INCR_1' 'INCR_2' 'INCR_3' 'INCR_4' 'INCR_5' 'INCR_6')

DATA_DIR="/data/mysql_data"

##
## ========== function =============
##

function wrlog() {
    echo "*** $1" >> ${RECOVER_LOG}
}

function check_week_dir() {

    if [[ ! -d ${WEEK_DIR} || ${WEEK_DIR} == "" ]];then
        echo "*** WEEK DIR is not exists!"
        exit 101
    fi

    if [[ ! -d ${WEEK_DIR}/FULL ]];then
        echo "*** ${WEEK_DIR}/FULL is not exists!"
        exit 102
    fi

    if [[ ${TO_DIR} == "" ]];then
        echo "*** TO_DIR ${TO_DIR} is empty!"
        exit 103
    fi

    if [[ ! -d ${WEEK_DIR}/${TO_DIR} ]];then
        echo "*** ${WEEK_DIR}/${TO_DIR} is not exists!"
        exit 104
    fi
}

function write_start_log() {

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${CURRENT_DATETIME} Begin Recover <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> ${RECOVER_LOG}

}


function decompress_xbstream() {

    if [[ -d "$2" ]];then
        wrlog "$2 is exists, rm -rf ..."
        rm -rf "$2"
    fi

    mkdir -p "$2"

    xbstream -x < $1 -C "$2" 2>> ${RECOVER_LOG}

    if [[ $? -eq 0 ]];then
        wrlog "DECOMPRESS Phase.xbstream SUCCESS."
    else
        wrlog "DECOMPRESS Phase.xbstream FAILED."
        exit 106
    fi

     innobackupex  --decompress  $2  2>> ${RECOVER_LOG}
     find $2  -name "*.qp" -exec rm -rf {} \;   
	 	 

    if [[ $? -eq 0 ]];then
        wrlog "DECOMPRESS Phase.innobackupex.decompress SUCCESS."
    else
        wrlog "DECOMPRESS Phase.innobackupex.decompress FAILED."
        exit 107
    fi

}

function only_recover_full {

    wrlog "WEEK DIR is ${WEEK_DIR}"
    wrlog "ONLY FULL BACKUP DIR is ${WEEK_DIR}/FULL"
    wrlog "DECOMPRESS XBSTREAM TO ${WEEK_DIR}/FULL/EXTRACT"

    decompress_xbstream "${WEEK_DIR}/FULL/mysql_backup_full.xbstream"  "${WEEK_DIR}/FULL/EXTRACT"

    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --apply-log "${WEEK_DIR}/FULL/EXTRACT" 2>> ${RECOVER_LOG}
    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --copy-back "${WEEK_DIR}/FULL/EXTRACT" 2>> ${RECOVER_LOG}

}

function do_incr_recover_base {

    wrlog "WEEK DIR is ${WEEK_DIR}"
    wrlog "INCR FULL BACKUP DIR is ${WEEK_DIR}/FULL"
    wrlog "DECOMPRESS XBSTREAM TO ${WEEK_DIR}/FULL/EXTRACT"

    decompress_xbstream "${WEEK_DIR}/FULL/mysql_backup_full.xbstream"  "${WEEK_DIR}/FULL/EXTRACT"

    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --apply-log --redo-only  "${WEEK_DIR}/FULL/EXTRACT" 2>> ${RECOVER_LOG}

}


function do_decompress_incr() {

    INCR_DIR=$1
    NUM=$(echo "${INCR_DIR}" | cut -d '_' -f 2)
    wrlog "INCR BACKUP DIR is ${WEEK_DIR}/${INCR_DIR}"
    wrlog "DECOMPRESS XBSTREAM TO ${WEEK_DIR}/${INCR_DIR}/EXTRACT"

    decompress_xbstream "${WEEK_DIR}/${INCR_DIR}/mysql_backup_incr_${NUM}.xbstream"  "${WEEK_DIR}/${INCR_DIR}/EXTRACT"

}


function do_incr_apply_log() {

    INCR_DIR=$1
    do_decompress_incr ${INCR_DIR}

    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --apply-log --redo-only  ${BASE_DIR} --incremental-dir="${WEEK_DIR}/${INCR_DIR}/EXTRACT" 2>> ${RECOVER_LOG}

}

function do_last_incr_apply_log() {

    INCR_DIR=$1
    do_decompress_incr ${INCR_DIR}

    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --apply-log  ${BASE_DIR} --incremental-dir="${WEEK_DIR}/${INCR_DIR}/EXTRACT" 2>> ${RECOVER_LOG}

}

function do_last_apply_log() {
 
    wrlog "do_last_apply_log for BASE_DIR: ${BASE_DIR}"
    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --apply-log  ${BASE_DIR}  2>> ${RECOVER_LOG}

}

function do_copy_back() {

    wrlog "do_copy_back to DATADIR (e.g. /etc/my.cnf)"
    innobackupex --defaults-file=${MYSQL_CNF} ${MYSQL_MULTI_GROUP} --copy-back  ${BASE_DIR}  2>> ${RECOVER_LOG}

}

function incr_recover() {

    wrlog ">>>>>>>>> incremental recover <<<<<<<<"

    do_incr_recover_base

    for incr_dir in ${INCR_DIRS[@]}
    do
        if [[ ! -d ${WEEK_DIR}/${incr_dir} ]];then
            wrlog "WARN ${incr_dir} is not exists, skipped it ..."
            continue
        fi

        if [[ ${incr_dir} == ${TO_DIR} ]];then
            do_last_incr_apply_log "${incr_dir}"
            break
        fi

        do_incr_apply_log ${incr_dir}
    done
 
    do_last_apply_log
    do_copy_back

}



function usage() {
    echo "Example:"
    echo "sh $0 -w /opt/backup/mysql/WEEK_50 -t INCR_4   # means recvoer from FULL to INCR_4"
    echo "sh $0 -w /opt/backup/mysql/WEEK_50 -t FULL   # means only recover FULL, no need INCR_X"
}

function check_data_dir() {

    multi_group=$(echo ${MYSQL_MULTI_GROUP} | cut -d '=' -f 2)

    if [[ ${multi_group} != "" ]];then
        DATA_DIR=$(cat ${MYSQL_CNF} | grep "\[${multi_group}\]" -A 8 | grep "datadir" | sed 's/ //g' | cut -d '=' -f 2)
    fi

    if [[ ${DATA_DIR} == "" ]];then
        echo "*** [${multi_group} not has datadir, please check ${MYSQL_CNF}]"
        return 108
    fi

    # 如果不存在该目录，则正确返回
    if [[ ! -d ${DATA_DIR} ]];then
        return 0
    fi

    # 如果存在，判断一下里面是否有内容
    num=$(ls ${DATA_DIR} | wc -l)
    if [[ ${num} -eq 0 ]];then
        return 0
    else
        return 109
    fi

}


function change_perm() {

    chown mysql:mysql ${DATA_DIR} -R

    res=$?
    if [[ ${res} -eq 0 ]];then
        echo "${DATA_DIR} Owner has been changed SUCCESS."
        echo ""
        echo ">>>>>>>>>>>>> We Don't Start MySQL For You. Please Do It By Yourself! <<<<<<<<<<<<<<"
        echo ""
    else
        echo "${DATA_DIR} Owner has been changed FAILED."
    fi

    return ${res}

}

#################  main #################

if [[ $# -eq 0 ]];then
    usage
    exit 10
fi

while getopts ":t:w:h" opt
do
    case $opt in
        't' )
            TO_DIR=$OPTARG
            ;;
        'w' )
            WEEK_DIR=$OPTARG
            ;;
        'h' )
            usage
            exit 0
            ;;
        '?' )
            echo "[ERROR] Args is error!"
            echo $@
            exit 100
            ;;
    esac
done

check_week_dir

check_data_dir

if [[ $? -ne 0  ]];then
    echo "*** datadir: ${DATA_DIR} is not empty, please use a new MySQL instance!"
    exit 110
fi

BAK_FULL_DIR="${WEEK_DIR}/FULL"
BASE_DIR="${BAK_FULL_DIR}/EXTRACT"

write_start_log


echo "Process... You can use command  'tail -f $(pwd)/${RECOVER_LOG}' in another  terminal window."

# 如果TO_DIR == FULL， 表示仅仅恢复一个全备
if [[ ${TO_DIR} == "FULL" ]];then
    wrlog ">>>>>>>>>  only only_recover_full <<<<<<<<"
    only_recover_full
    res=$?

    if [[ ${res} -eq 0 ]];then
        echo "RECOVER IS SUCCESS."
        change_perm
        res=$?
    else
        echo "RECOVER IS FAILED."
    fi

    exit ${res}
fi


incr_recover
res=$?

if [[ ${res} -eq 0 ]];then
    echo "RECOVER IS SUCCESS."
    change_perm
    res=$?
else
    echo "RECOVER IS FAILED."
fi

exit ${res}

