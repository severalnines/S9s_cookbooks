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

case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'

  default['mysql']['install_dir']   = "/"
  default['mysql']['basedir']      = "/usr"
  default['mysql']['bindir']       = default['mysql']['basedir'] +"/bin"

  default['mysql']['ndb_bindir']   = default['mysql']['basedir'] +"/bin"

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

  default['mysql']['installdir']   = "/"
  default['mysql']['basedir']      = "/usr"
  default['mysql']['bindir']       = default['mysql']['basedir'] +"/bin"

  default['mysql']['ndb_bindir']   = default['mysql']['basedir'] +"/bin"

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

default['xtra']['sleep'] = 60
default['mysql']['root_password'] = "password"
default['mysql']['mysql_bin'] = default['mysql']['bindir'] + "/mysql"

default['mysql']['datadir'] = "/var/lib/mysql"
default['mysql']['rundir']  = "/var/run/mysqld"
default['mysql']['pid_file'] = default['mysql']['datadir'] + "/mysqld.pid"
default['mysql']['socket']  = default['mysql']['rundir'] + "/mysqld.sock"

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

#OTHER THINGS, BUFFERS ETC
default['mysql']['misc']['max_connections'] = 200
default['mysql']['misc']['thread_cache_size'] = 64
default['mysql']['misc']['table_open_cache'] = 1024

default['mysql']['repl_user']     = "repl"
default['mysql']['repl_password'] = "repl"

default['sql']['cmon_schema'] = default['install_dir_cmon'] + "/cmon/sql/cmon_db.sql"
default['sql']['cmon_data']   = default['install_dir_cmon'] + "/cmon/sql/cmon_data.sql"
default['sql']['controller_grants'] = default['install_dir_cmon'] + "/cmon/sql/cmon_controller_grants.sql"
default['sql']['controller_agent_grants'] = default['install_dir_cmon'] + "/cmon/sql/cmon_controller_agent_grants.sql"
default['sql']['agent_grants'] = default['install_dir_cmon'] + "/cmon/sql/cmon_agent_grants.sql"

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

default['mysql']['script_dir']    = "/usr/bin"

#default['cmon']['misc']['cmon_core_dir'] = ""
default['misc']['ndb_binary'] = ""
default['misc']['BACKUPDIR'] = ""
default['misc']['IDENTITY']  = default['controller']['ssh_key']
