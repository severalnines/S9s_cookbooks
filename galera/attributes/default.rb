case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'

  default['mysql']['servicename'] = "mysqld"
  default['xtra']['packages'] = "openssl psmisc libaio wget rsync nc"

else

  default['mysql']['servicename'] = "mysql"
  default['xtra']['packages'] = "libssl0.9.8 psmisc libaio1 wget rsync netcat"

end

default['galera']['install_dir'] = "/usr/local"

default['mysql']['basedir'] = "#{galera['install_dir']}/mysql"
default['mysql']['bindir']  = "#{mysql['basedir']}/bin"

default['xtra']['sleep'] = 60
default['mysql']['root_password'] = "password"
default['mysql']['mysqlbin'] = "#{mysql['bindir']}/mysql"

default['mysql']['datadir'] = "/var/lib/mysql"
default['mysql']['rundir']  = "/var/run/mysqld"
default['mysql']['pid_file'] = "#{mysql['datadir']}/mysqld.pid"
default['mysql']['socket']  = "#{mysql['rundir']}/mysqld.sock"
default['mysql']['port']    = 3306
default['mysql']['tmpdir']  = "/tmp"

default['mysql']['innodb']['buffer_pool_size'] = "256M"
default['mysql']['innodb']['flush_log_at_trx_commit'] = 2
default['mysql']['innodb']['file_per_table'] = 1
default['mysql']['innodb']['doublewrite'] = 0
default['mysql']['innodb']['log_file_size'] = "512M"
default['mysql']['innodb']['log_files_in_group'] = 2
default['mysql']['innodb']['buffer_pool_instances'] = 1
default['mysql']['innodb']['max_dirty_pages_pct'] = 75
default['mysql']['innodb']['thread_concurrency'] = 0
default['mysql']['innodb']['concurrency_tickets'] = 5000
default['mysql']['innodb']['thread_sleep_delay'] = 10000
default['mysql']['innodb']['lock_wait_timeout'] = 50
default['mysql']['innodb']['io_capacity'] = 200
default['mysql']['innodb']['read_io_threads'] = 4
default['mysql']['innodb']['write_io_threads'] = 4

default['mysql']['innodb']['file_format'] = "barracuda"
default['mysql']['innodb']['flush_method'] = "O_DIRECT"
default['mysql']['innodb']['locks_unsafe_for_binlog'] = 1
default['mysql']['innodb']['autoinc_lock_mode'] = 2
default['mysql']['misc']['condition_pushdown'] = 1

default['mysql']['misc']['binlog_format'] = "ROW"

#OTHER THINGS, BUFFERS ETC
default['mysql']['misc']['max_connections'] = 512
default['mysql']['misc']['thread_cache_size'] = 512
default['mysql']['misc']['table_open_cache'] = 1024
#lower-case-table-names = 0

##
## WSREP options
##

# Full path to wsrep provider library or 'none'
case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'
  default['wsrep']['provider'] = "/usr/lib64/galera/libgalera_smm.so"
else
  default['wsrep']['provider'] = "/usr/lib/galera/libgalera_smm.so"
end

default['wsrep']['port'] = 4567

# Logical cluster name. Should be the same for all nodes.
default['wsrep']['cluster_name'] = "my_galera_cluster"

# How many threads will process writesets from other nodes
# (more than one untested)
default['wsrep']['slave_threads'] = 1

# Generate fake primary keys for non-PK tables (required for multi-master
# and parallel applying operation)
default['wsrep']['certify_nonPK'] = 1

# Maximum number of rows in write set
default['wsrep']['max_ws_rows'] = 131072

# Maximum size of write set
default['wsrep']['max_ws_size'] = 1073741824

# how many times to retry deadlocked autocommits
default['wsrep']['retry_autocommit'] = 1

# change auto_increment_increment and auto_increment_offset automatically
default['wsrep']['auto_increment_control'] = 1

# enable "strictly synchronous" semantics for read operations 
default['wsrep']['casual_reads'] = 0

##
## WSREP State Transfer options
##

default['wsrep']['user'] = "wsrep_sst"
default['wsrep']['password'] = "wsrep"

# State Snapshot Transfer method
default['wsrep']['sst_method'] = "rsync"

# Address on THIS node to receive SST at. DON'T SET IT TO DONOR ADDRESS!!!
# (SST method dependent. Defaults to the first IP of the first interface)
#wsrep_sst_receive_address=<%= node['ipaddress'] %>

# SST authentication string. This will be used to send SST to joining nodes.
# Depends on SST method. For mysqldump method it is wsrep_sst:<wsrep password>
default['wsrep']['sst_auth'] = default['wsrep']['user'] + ":" + default['wsrep']['password']

