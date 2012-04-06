default['cmon']['remote']['mysql_user']        = "cmon"
default['cmon']['remote']['mysql_hostname']    = "set-me-to-cmon-controller-host-ip"
default['cmon']['remote']['mysql_password']    = "cmon"
default['cmon']['remote']['mysql_port']        = 3306
default['cmon']['remote']['ndb_connectstring'] = "127.0.0.1"

default['cmon']['cmon_password']      = 'cmon'
default['cmon']['mode']['agent']      = 'agent'
default['cmon']['mode']['controller'] = 'controller'
default['cmon']['mode']['dual']       = 'dual'

default['cmon']['local']['mysql_user']     = "root"
default['cmon']['local']['mysql_hostname'] = "127.0.0.1"
default['cmon']['local']['mysql_password'] = "password"
default['cmon']['local']['mysql_port']     = 3306
default['cmon']['local']['hostname']       = "set-me-to-valid-ip"

default['cmon']['cluster_id']      = 1
default['cmon']['cluster_name']    = "default_name"
default['cmon']['cluster_type']    = "replication"

default['cmon']['install_dir_cmon']   = "/usr/local"
default['cmon']['install_configpath'] = "/etc"

default['cmon']['mysql']['install_dir']   = "/usr/local"
default['cmon']['mysql']['base_dir']      = "/usr/local/mysql"
default['cmon']['mysql']['lib_dir']       = "/usr/local/mysql/lib"
default['cmon']['mysql']['bin_dir']       = "/usr/local/mysql/bin"
default['cmon']['mysql']['libexec']       = "/usr/local/mysql/bin"
default['cmon']['mysql']['script_dir']    = "/usr/local/mysql/scripts"
default['cmon']['mysql']['repl_user']     = ""
default['cmon']['mysql']['repl_password'] = "repl"

default['cmon']['rrd']['image_dir'] = "/var/www/cmon/graphs"
default['cmon']['rrd']['rrdtool']   = "/usr/local/bin/rrdtool"
default['cmon']['rrd']['data_dir']  = "/var/lib/cmon"

default['cmon']['misc']['os_user']   = "root"
default['cmon']['misc']['WWWROOT']  = "/var/www/"
default['cmon']['misc']['WEB_USER'] = "www-data"

default['cmon']['misc']['pid_file'] = "/var/run/cmon.pid"
# /run/lock/ for ubuntu but for other dists?
default['cmon']['misc']['lock_dir'] = "/run/lock"
default['cmon']['misc']['log_file'] = "/var/log/cmon.log"
default['cmon']['misc']['nodaemon'] = 1
default['cmon']['misc']['db_stats_collection_interval']=30
default['cmon']['misc']['host_stats_collection_interval']=30

#default['cmon']['misc']['cmon'_core_dir'] = ""
#default['cmon']['misc']['ndb_binary']=
default['cmon']['misc']['BACKUPDIR'] = ""
default['cmon']['misc']['IDENTITY']  = ""
default['cmon']['misc']['IDENTITY2'] = ""

#default['mysql']['bind_address'] = attribute?('cloud') ? cloud['local_ipv4'] : ipaddress
case node["platform"]
when "centos", "redhat", "fedora", "suse", "scientific", "amazon"
  default['cmon']['agent']['packages'] = %w(psmisc libaio)
  default['cmon']['controller']['packages'] = %w(rrdtool mysql mysql-server)
  default['cmon']['web']['packages'] = %w(httpd php php-mysql php-gd)

	if FileTest.exist?("/usr/sbin/chkconfig")
		default['cmon']['service']['too'] = "/usr/sbin/chkconfig"
	elsif FileTest.exist? ("/usr/bin/chkconfig")
		default['cmon']['service']['tool'] = "/usr/bin/chkconfig"
	elsif FileTest.exist? ("/sbin/chkconfig")
		default['cmon']['service']['tool'] = "/sbin/chkconfig"		
	end

  default['mysql']['package_name'] = "mysql-server"
  default['mysql']['service_name'] = "mysqld"

else
  default['cmon']['agent']['packages'] = %w(psmisc libaio1)
  default['cmon']['controller']['packages'] = %w(rrdtool mysql-server)
  default['cmon']['web']['packages'] = %w(apache2 php5-mysql php5-gd)
	default['cmon']['service']['tool'] = "/usr/sbin/update-rc.d"

  default['mysql']['package_name'] = "mysql-server"
  default['mysql']['service_name'] = "mysql"
end
