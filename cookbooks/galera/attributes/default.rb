
# Vagrant hostonly fix
# Cookbook Name:: vagrant-ohai
# Attribute:: default
#
# Copyright 2010, Opscode, Inc
# FHS location would be /var/lib/chef/ohai_plugins or similar.           
default["vagrant-ohai"]["plugin_path"] = "/etc/chef/vagrant_ohai_plugins"

case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'

  default['mysql']['servicename'] = "mysqld"
  default['xtra']['packages'] = "openssl psmisc libaio wget rsync nc"

else

  default['mysql']['servicename'] = "mysql"
  default['xtra']['packages'] = "libssl0.9.8 psmisc libaio1 wget rsync netcat"

end

default['xtra']['sleep'] = 30

default['mysql']['install_dir'] = "/usr/local"
default['mysql']['base_dir'] = "#{mysql['install_dir']}/mysql"
default['mysql']['bin_dir']  = "#{mysql['base_dir']}/bin"
default['mysql']['mysql_bin'] = "#{mysql['bin_dir']}/mysql"

default['mysql']['root_password'] = "password"

default['mysql']['conf_dir']  = '/etc'
default['mysql']['data_dir'] = "/var/lib/mysql"
default['mysql']['run_dir']  = "/var/run/mysqld"
default['mysql']['pid_file'] = "#{mysql['data_dir']}/mysqld.pid"
default['mysql']['socket']  = "#{mysql['run_dir']}/mysqld.sock"
default['mysql']['port']    = 3306
default['mysql']['tmp_dir']  = "/tmp"

default['mysql']['tunable']['buffer_pool_size'] = "256M"
default['mysql']['tunable']['flush_log_at_trx_commit'] = 2
default['mysql']['tunable']['file_per_table'] = 1
default['mysql']['tunable']['doublewrite'] = 0
default['mysql']['tunable']['log_file_size'] = "512M"
default['mysql']['tunable']['log_files_in_group'] = 2
default['mysql']['tunable']['buffer_pool_instances'] = 1
default['mysql']['tunable']['max_dirty_pages_pct'] = 75
default['mysql']['tunable']['thread_concurrency'] = 0
default['mysql']['tunable']['concurrency_tickets'] = 5000
default['mysql']['tunable']['thread_sleep_delay'] = 10000
default['mysql']['tunable']['lock_wait_timeout'] = 50
default['mysql']['tunable']['io_capacity'] = 200
default['mysql']['tunable']['read_io_threads'] = 4
default['mysql']['tunable']['write_io_threads'] = 4

default['mysql']['tunable']['file_format'] = "barracuda"
default['mysql']['tunable']['flush_method'] = "O_DIRECT"
default['mysql']['tunable']['locks_unsafe_for_binlog'] = 1
default['mysql']['tunable']['autoinc_lock_mode'] = 2
default['mysql']['tunable']['condition_pushdown'] = 1

default['mysql']['tunable']['binlog_format'] = "ROW"

#OTHER THINGS, BUFFERS ETC
default['mysql']['tunable']['max_connections'] = 512
default['mysql']['tunable']['thread_cache_size'] = 512
default['mysql']['tunable']['table_open_cache'] = 1024
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

