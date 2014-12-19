case node['platform']
when 'centos', 'redhat', 'fedora', 'scientific', 'amazon'
	default['repo_path'] = "/etc/yum.repos.d"
	default['repo_file'] = "s9s-repo.repo"
	default['update_repo'] = "yum clean all"

	default['packages'] = %w(httpd php php-mysql php-ldap php-gd mod_ssl openssl bind-utils nc curl cronie mailx wget mysql mysql-server clustercontrol-controller clustercontrol clustercontrol-cmonapi)

	default['apache']['service_name'] = "httpd"
	default['apache']['config'] = '/etc/httpd/conf/httpd.conf'
	default['apache']['ssl_config'] = '/etc/httpd/conf.d/ssl.conf'
	default['apache']['wwwroot'] = '/var/www/html'
	default['apache']['user'] = 'apache'
	default['apache']['extra_opt'] = nil
	default['apache']['cert_file'] = "/etc/pki/tls/certs/s9server.crt"
	default['apache']['key_file'] = "/etc/pki/tls/certs/s9server.key"
	default['apache']['cert_regex'] = "s|^SSLCertificateFile.*|SSLCertificateFile"
	default['apache']['key_regex'] = "s|^SSLCertificateKeyFile.*|SSLCertificateKeyFile"

	default['mysql']['service_name'] = "mysqld"
	default['mysql']['conf_file'] = "/etc/my.cnf"

when 'debian', 'ubuntu'
	default['repo_path'] = "/etc/apt/sources.list.d"
	default['repo_file'] = "s9s-repo.list"
	default['update_repo'] = "apt-get update"

	default['packages']	= %w(apache2 libapache2-mod-php5 php5-common php5-mysql php5-gd php5-ldap php5-json php5-curl dnsutils curl mailutils wget mysql-client mysql-server clustercontrol-controller clustercontrol clustercontrol-cmonapi)

	default['apache']['service_name'] = "apache2"
	default['apache']['extra_opt'] = nil
	default['apache']['user'] = 'www-data'
	default['apache']['cert_file'] = "/etc/ssl/certs/s9server.crt"
	default['apache']['key_file'] = "/etc/ssl/private/s9server.key"
	default['apache']['cert_regex'] = "s|^[ \t]*SSLCertificateFile.*|SSLCertificateFile"
	default['apache']['key_regex'] = "s|^[ \t]*SSLCertificateKeyFile.*|SSLCertificateKeyFile"

	case node['platform_version']
	when '14.04'
		default['apache']['wwwroot'] = '/var/www/html'
		default['apache']['extra_opt'] = 'Require all granted'
		default['apache']['config'] = '/etc/apache2/sites-available/s9s.conf'
		default['apache']['ssl_config'] = '/etc/apache2/sites-available/s9s-ssl.conf'
		default['apache']['ssl_vhost'] = 's9s-ssl.conf'
	else
		default['apache']['wwwroot'] = '/var/www'
		default['apache']['config']	= '/etc/apache2/sites-available/default'
		default['apache']['ssl_config'] = '/etc/apache2/sites-available/default-ssl'
		default['apache']['ssl_vhost'] = 'default-ssl'
	end

	default['mysql']['service_name'] = "mysql"
	default['mysql']['conf_file'] = "/etc/mysql/my.cnf"
end

default['cluster_id'] = 1
default['cluster_name'] = "cluster_#{cluster_id}"
default['cluster_type'] = "galera"
default['email_address'] = 'admin@localhost.xyz'
default['api_token'] = ""
default['ssh_user'] = "root"
default['user_home'] = "/root"
default['backup_dir'] = "#{user_home}/backups"
default['staging_dir'] = "#{user_home}/s9s_tmp"
default['ssh_port'] = 22
default['ssh_key'] = "#{user_home}/.ssh/id_rsa"
default['ssh_identity'] = "#{ssh_key}"
default['sudo_password'] = nil

default['cmon']['mysql_user'] = "cmon"
default['cmon']['mysql_hostname'] = "#{ipaddress}"
default['cmon']['mysql_root_password'] = "password"
default['cmon']['mysql_password'] = "cmon"
default['cmon']['mysql_port'] = 3306
default['cmon']['pid_file'] = "/var/run/"
default['cmon']['log_file'] = "/var/log/cmon.log"
default['cmon']['daemonize'] = 1
default['cmon']['ndb_binary']	= "ndbd"
default['cmon']['mysql_basedir'] = "/usr"
default['cmon']['mysql_datadir'] = "/var/lib/mysql"
default['cmon']['mysql_bindir'] = "#{cmon['mysql_basedir']}/bin"
default['cmon']['mysql_bin'] = "#{cmon['mysql_basedir']}/bin/mysql"
default['cmon']['mongodb_basedir'] = "/usr"
default['cmon']['monitored_mountpoints'] = "/var/lib/mysql"

default['cmon']['mysql_server_addresses'] = ""
default['cmon']['datanode_addresses'] = ""
default['cmon']['mgmnode_addresses'] = ""
default['cmon']['ndb_connectstring'] = ""

default['cmon']['mongodb_server_addresses'] = ""
default['cmon']['mongoarbiter_server_addresses'] = ""
default['cmon']['mongocfg_server_addresses'] = ""
default['cmon']['mongos_server_addresses'] = ""

default['mysql']['root_password'] = "password"
default['mysql']['vendor'] = "percona"
default['mysql']['basedir'] = "/usr"
default['mysql']['bindir'] = "#{mysql['basedir']}/bin"
default['mysql']['bin'] = "#{mysql['basedir']}/bin/mysql"

default['sql']['cmon_schema'] = "/usr/share/cmon/cmon_db.sql"
default['sql']['cmon_data'] = "/usr/share/cmon/cmon_data.sql"
default['sql']['cc_schema'] = "#{apache['wwwroot']}/clustercontrol/sql/dc-schema.sql"

default['cmonapi']['bootstrap']	= "#{apache['wwwroot']}/cmonapi/config/bootstrap.php"
default['cmonapi']['database'] = "#{apache['wwwroot']}/cmonapi/config/database.php"
default['ccui']['bootstrap'] = "#{apache['wwwroot']}/clustercontrol/bootstrap.php"
