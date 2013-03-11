case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'

  default['agent']['packages'] = %w(psmisc libaio sysstat)
  default['controller']['packages'] = %w(rrdtool mysql mysql-server nc wget)

  default['controller']['mysql_packages'] = %w(mysql mysql-server)
  default['controller']['rrdtool_packages'] = %w(rrdtool)

  default['web']['packages'] = %w(httpd php php-mysql php-gd)

  default['mysql']['service_name'] = "mysqld"

  default['misc']['wwwroot'] = "/var/www/html"
  default['misc']['web_user'] = "apache"

  default['apache']['service_name'] = "httpd"
  default['apache']['default-site'] = '/etc/httpd/conf/httpd.conf'

  default['rrd']['imagedir'] = "/var/www/html/cmon/graphs"

else

  default['agent']['packages'] = %w(psmisc libaio1 sysstat)
  default['controller']['packages'] = %w(rrdtool mysql-server nc wget)

  default['controller']['mysql_packages'] = %w(mysql-server)
  default['controller']['rrdtool_packages'] = %w(rrdtool)

  default['web']['packages'] = %w(apache2 libapache2-mod-php5 php5-mysql php5-gd)

  default['mysql']['service_name'] = "mysql"

  default['misc']['wwwroot'] = "/var/www"
  default['misc']['web_user'] = "www-data"

  default['apache']['service_name'] = "apache2"
  default['apache']['default-site'] = '/etc/apache2/sites-available/default'

  default['rrd']['imagedir'] = "/var/www/cmon/graphs"

end

default['install_dir_cmon']   = "/usr/local"
default['install_config_path'] = "/etc"

default['cluster_id']      = 1
default['cluster_name']    = "default_cluster_1"
default['cluster_type']    = "replication"

default['controller']['mysql_user']        = "cmon"
default['controller']['mysql_hostname']    = "from-databag"
default['controller']['mysql_password']    = "cmon"
default['controller']['mysql_port']        = 3306
default['controller']['ndb_connectstring'] = "from-databag"
default['controller']['ssh_key'] = "/root/.ssh/id_rsa"

default['cmon_password']      = "cmon"

default['mode']['agent']      = "agent"
default['mode']['controller'] = "controller"
default['mode']['dual']       = "dual"

default['agent']['mysql_user']     = "cmon"
default['agent']['mysql_hostname'] = "127.0.0.1"
default['agent']['mysql_password'] = "cmon"
default['agent']['mysql_port']     = 3306
default['agent']['hostname']       = node['ipaddress']

default['cmon_mysql']['install_dir']   = "/"
default['cmon_mysql']['basedir']      = "/usr"
default['cmon_mysql']['bindir']       = "#{cmon_mysql['basedir']}/bin"
default['cmon_mysql']['ndb_bindir']   = "#{cmon_mysql['basedir']}/bin"

default['xtra']['sleep'] = 60
default['cmon_mysql']['root_password'] = "password"
default['cmon_mysql']['mysql_bin'] = "#{cmon_mysql['bindir']}/mysql"

default['cmon_mysql']['datadir'] = "/var/lib/mysql"
default['cmon_mysql']['rundir']  = "/var/run/mysqld"
default['cmon_mysql']['pid_file'] = "#{cmon_mysql['datadir']}/mysqld.pid"
default['cmon_mysql']['socket']  = "#{cmon_mysql['rundir']}/mysqld.sock"

default['cmon_mysql']['port']    = 3306
default['cmon_mysql']['tmpdir']  = "/tmp"

default['cmon_mysql']['innodb']['buffer_pool_size'] = "256M"
default['cmon_mysql']['innodb']['flush_log_at_trx_commit'] = 2
default['cmon_mysql']['innodb']['file_per_table'] = 1
default['cmon_mysql']['innodb']['doublewrite'] = 0
default['cmon_mysql']['innodb']['log_file_size'] = "512M"
default['cmon_mysql']['innodb']['log_files_in_group'] = 2
default['cmon_mysql']['innodb']['buffer_pool_instances'] = 1
default['cmon_mysql']['innodb']['max_dirty_pages_pct'] = 75
default['cmon_mysql']['innodb']['thread_concurrency'] = 0
default['cmon_mysql']['innodb']['concurrency_tickets'] = 5000
default['cmon_mysql']['innodb']['thread_sleep_delay'] = 10000
default['cmon_mysql']['innodb']['lock_wait_timeout'] = 50
default['cmon_mysql']['innodb']['io_capacity'] = 200
default['cmon_mysql']['innodb']['read_io_threads'] = 4
default['cmon_mysql']['innodb']['write_io_threads'] = 4

default['cmon_mysql']['innodb']['file_format'] = "barracuda"
default['cmon_mysql']['innodb']['flush_method'] = "O_DIRECT"

#OTHER THINGS, BUFFERS ETC
default['cmon_mysql']['misc']['max_connections'] = 200
default['cmon_mysql']['misc']['thread_cache_size'] = 64
default['cmon_mysql']['misc']['table_open_cache'] = 1024

default['cmon_mysql']['repl_user']     = "repl"
default['cmon_mysql']['repl_password'] = "repl"

default['sql']['cmon_schema'] = "#{install_dir_cmon}/cmon/sql/cmon_db.sql"
default['sql']['cmon_data']   = "#{install_dir_cmon}/cmon/sql/cmon_data.sql"
default['sql']['controller_grants'] = "#{install_dir_cmon}/cmon/sql/cmon_controller_grants.sql"
default['sql']['controller_agent_grants'] = "#{install_dir_cmon}/cmon/sql/cmon_controller_agent_grants.sql"
default['sql']['agent_grants'] = "#{install_dir_cmon}/cmon/sql/cmon_agent_grants.sql"

default['rrd']['rrdtool']   = "/usr/bin/rrdtool"
default['rrd']['datadir']  = "/var/lib/cmon"

default['misc']['os_user']  = "root"
default['misc']['core_dir'] = "/root/s9s"

default['misc']['pid_file'] = "/var/run/cmon.pid"
# /run/lock/ for ubuntu but for other dists?
default['misc']['lock_dir'] = "/run/lock"
default['misc']['log_file'] = "/var/log/cmon.log"
default['misc']['nodaemon'] = 1
default['misc']['db_stats_collection_interval'] = 30
default['misc']['host_stats_collection_interval'] = 30

default['cmon_mysql']['script_dir']    = "/usr/bin"

#default['cmon']['misc']['cmon_core_dir'] = ""
default['misc']['ndb_binary'] = ""
default['misc']['BACKUPDIR'] = ""
default['misc']['IDENTITY']  = "#{controller['ssh_key']}"
