#######################################################
# $Name: MySQL_batchly_inserts.sh
# $Version: v1.0
# $Author: Ethan_Yang
# $Create Date: 2020-02-21
# $Description: Under MySQL 8.0,how to xinsert a mount of datas batchly.
#######################################################

--测试表
CREATE TABLE employees (      
id INT NOT NULL,      
  fname VARCHAR(30),      
  lname VARCHAR(30),      
  birth TIMESTAMP,      
  hired DATE NOT NULL DEFAULT '1970-01-01',      
  separated DATE NOT NULL DEFAULT '9999-12-31',      
  job_code INT NOT NULL,      
  store_id INT NOT NULL
);

--批量写入存储过程
DROP PROCEDURE IF EXISTS BatchInsert;      


delimiter    -- 把界定符改成双斜杠      
CREATE PROCEDURE BatchInsert(IN init INT, IN loop_time INT)  -- 第一个参数为初始ID号（可自定义），第二个位生成MySQL记录个数      
  BEGIN      
DECLARE Var INT;      
DECLARE ID INT;      
      SET Var = 0;      
      SET ID = init;      
WHILE Var < loop_time DO
          insert into employees      
          (id, fname, lname, birth, hired, separated, job_code, store_id)       
          values       
          (ID, CONCAT('ethanY', ID), CONCAT('GaussDB', ID), Now(), Now(), Now(), 1, ID);      
          SET ID = ID + 1;      
          SET Var = Var + 1;      
      END WHILE;      
  END;      
//      
delimiter ;  -- 界定符改回分号

--批量写入20万条
-- 开启事务插入,否则会很慢      
      
begin;      
CALL BatchInsert(1, 200000);      
commit;      
      
Query OK, 1 row affected (7.53 sec)

--使用insert into继续批量写入
mysql> insert into employees select * from employees;      
Query OK, 200000 rows affected (1.61 sec)      
Records: 200000  Duplicates: 0  Warnings: 0  

--1.1亿全量数据更新
mysql> update employees set lname=lname||'new';  
Query OK, 110400000 rows affected, 65535 warnings (21 min 30.34 sec)  
Rows matched: 110400000  Changed: 110400000  Warnings: 220800000



