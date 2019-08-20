#!/bin/bash

#######################################################
# $Name: cp_db_tables.sh
# $Version: v1.0
# $Author: ethan_yang
# $Create Date: 2019-08-20
# $Description: Wanna to copy the tables from db:ts_db_01 to db:ts_db_02
#######################################################

# wanna to rename database ethandb to ts_db_01;

mysql -uroot -pmysql -h 10.10.178.112 -P 3308 -e 'create database if not exists ts_db_02'
list_table=$(mysql -uroot -pmysql -h 10.10.178.112 -P 3308 -Nse "select table_name from information_schema.TABLES \
where TABLE_SCHEMA='ts_db_01'")

for table in $list_table
do
    mysql -uroot -pmysql -h 10.10.178.112 -P 3308 -e "rename table ts_db_01.$table to ts_db_02.$table"
done
