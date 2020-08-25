#######################################################
# $Name: my.cnf_MySQL.sh
# $Version: v1.0
# $Author: Ethan_Yang
# $Create Date: 2020-08-25
# $Description: Initial parameter file of creating mysql
#######################################################

[mysql]
default-character-set = utf8mb4
prompt="\u@db1 \R:\m:\s [\d]> "
no-auto-rehash

[mysqld]
########basic settings########
server-id = 100
port = 3306
user = mysql
bind_address = 0.0.0.0
autocommit = 1
character_set_server=utf8mb4
datadir = /data/mysql_data
transaction_isolation = READ-COMMITTED
explicit_defaults_for_timestamp = 1

########modify the format of time recording#######
log_timestamps=SYSTEM

tmpdir = /tmp
max_allowed_packet = 1073741824

event_scheduler = 1
sql_mode = "STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ZERO_IN_DATE,NO_ZERO_DATE"

# connection #
interactive_timeout = 1800
wait_timeout = 900
lock_wait_timeout = 120
skip_name_resolve = 1
max_connections = 2500
max_connect_errors = 1000000

# table cache performance settings #
table_open_cache = 4096
table_definition_cache = 4096
table_open_cache_instances = 128

# session memory settings #
read_buffer_size = 16M
read_rnd_buffer_size = 32M
sort_buffer_size = 32M
tmp_table_size = 64M
join_buffer_size = 128M
thread_cache_size = 64
lower_case_table_names = 1

########log settings########
log_error = error.log
slow_query_log = 0
slow_query_log_file = slow.log
log_queries_not_using_indexes = 1
log_slow_admin_statements = 1
log_slow_slave_statements = 1
log_throttle_queries_not_using_indexes = 0
expire_logs_days = 7
long_query_time = 2
min_examined_row_limit = 100
binlog-rows-query-log-events = 1
log_bin_trust_function_creators = 1
log_slave_updates = 1

########innodb settings########
innodb_page_size = 16K
innodb_buffer_pool_size = 1G
innodb_buffer_pool_instances = 4
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_lru_scan_depth = 2000
innodb_lock_wait_timeout = 5
innodb_io_capacity = 1000
innodb_io_capacity_max = 1500
innodb_flush_method = O_DIRECT
innodb_file_format = Barracuda
innodb_file_format_max = Barracuda
#innodb_log_group_home_dir = /redolog/
#innodb_undo_directory = /undolog/
innodb_undo_logs = 128
innodb_undo_tablespaces = 3
innodb_flush_neighbors = 1
innodb_flush_log_at_trx_commit = 1
innodb_log_file_size = 4G
innodb_log_files_in_group = 2
innodb_log_buffer_size = 16777216
innodb_purge_threads = 4
innodb_large_prefix = 1
innodb_thread_concurrency = 64
innodb_print_all_deadlocks = 1
innodb_strict_mode = 1
innodb_sort_buffer_size = 67108864
innodb_write_io_threads = 16
innodb_read_io_threads = 16
innodb_file_per_table = 1
innodb_stats_persistent_sample_pages = 64
innodb_autoinc_lock_mode = 2
innodb_online_alter_log_max_size=1G
innodb_open_files=4096

#######replication settings########
master_info_repository = TABLE
relay_log_info_repository = TABLE
log_bin = bin.log
sync_binlog = 1
gtid_mode = on
enforce_gtid_consistency = 1
log_slave_updates
binlog_format = ROW
binlog_rows_query_log_events = 1
binlog_gtid_simple_recovery = 1
relay_log = relay.log
relay_log_recovery = 1
slave_pending_jobs_size_max=2147483648

slave_skip_errors = ddl_exist_errors
slave-rows-search-algorithms = 'INDEX_SCAN,HASH_SCAN'
plugin_dir=/usr/local/mysql/lib/plugin

########semi sync replication settings########
#plugin_load = "validate_password.so;rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"

plugin_load = "rpl_semi_sync_master=semisync_master.so;rpl_semi_sync_slave=semisync_slave.so"
loose_rpl_semi_sync_master_enabled = 1
loose_rpl_semi_sync_slave_enabled = 1
loose_rpl_semi_sync_master_timeout = 5000

########password#########
plugin-load-add = validate_password.so
validate-password=FORCE_PLUS_PERMANENT
validate_password_policy=MEDIUM

#########control#########
plugin-load-add=connection_control.so
connection_control=FORCE_PLUS_PERMANENT
connection_control_failed_connections_threshold=10
connection_control_min_connection_delay=30000

#########server audit#########
##[timestamp],[serverhost],[username],[host],[connectionid],
##[queryid],[operation],[database],[object],[retcode]


plugin-load-add=server_audit.so
#server_audit=FORCE_PLUS_PERMANENT
#server_audit_logging=ON
#server_audit_events=connect,query_ddl
#server_audit_file_rotate_size=50000000
#server_audit_file_rotations=10

# need change it
#report-host=10.10.180.195

[mysqld-5.6]
# metalock performance settings
metadata_locks_hash_instances=64

[mysqld-5.7]
# new innodb settings #
loose_innodb_numa_interleave=1
innodb_buffer_pool_dump_pct = 40
innodb_page_cleaners = 8
innodb_undo_log_truncate = 1
innodb_max_undo_log_size = 2G
innodb_purge_rseg_truncate_frequency = 128
# new replication settings #
slave-parallel-type = LOGICAL_CLOCK
slave-parallel-workers = 4
slave_preserve_commit_order=1
slave_transaction_retries=128
# other change settings #
binlog_gtid_simple_recovery=1
log_timestamps=system
show_compatibility_56=on

# performance_schema #
performance_schema_digests_size = 35000
max_digest_length = 4096
performance_schema_max_digest_length = 4096
performance_schema_max_table_instances=35000


#for master_standby_trigger
log_bin_trust_function_creators=1


[mysqld_multi]
mysqld = /usr/local/mysql/bin/mysqld_safe
mysqladmin = /usr/local/mysql/bin/mysqladmin
user = multi_admin
pass = Infra5@Gep0int
log = /var/log/mysqld_multi.log


[mysqld3307]
server-id = 101
datadir = /data/data3307
basedir = /usr/local/mysql
port = 3307
socket = /tmp/mysql3307.sock
innodb_page_size = 16K

[mysqldump]
quick
max_allowed_packet = 256M
