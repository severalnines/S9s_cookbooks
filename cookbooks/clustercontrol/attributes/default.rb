case node['platform']
when 'centos', 'redhat', 'fedora', 'scientific', 'amazon'
	default['repo_path'] = "/etc/yum.repos.d"
	default['repo_file'] = "s9s-repo.repo"
	default['update_repo'] = "yum clean all"

	if node['platform_version'].to_f <= 6
		default['packages'] = %w(httpd php php-mysql php-ldap php-gd mod_ssl openssl bind-utils nc curl cronie mailx wget mysql mysql-server clustercontrol-controller clustercontrol clustercontrol-cmonapi)
		default['mysql']['service_name'] = "mysqld"
	else
		default['packages'] = %w(httpd php php-mysql php-ldap php-gd mod_ssl openssl bind-utils nc curl cronie mailx wget mariadb mariadb-server clustercontrol-controller clustercontrol clustercontrol-cmonapi)
		default['mysql']['service_name'] = "mariadb"
	end

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

	if (node['platform'] == "ubuntu" && node['platform_version'].to_f >= 14.04 ) || (node['platform'] == "debian" && node['platform_version'].to_f >= 8)
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

default['api_token'] = ""
default['ssh_user'] = "root"
default['user_home'] = "/root"
default['ssh_key'] = "/root/.ssh/id_rsa"
default['cmon']['mysql_user'] = "cmon"
default['cmon']['mysql_hostname'] = "#{ipaddress}"
default['cmon']['mysql_root_password'] = "password"
default['cmon']['mysql_password'] = "cmon"
default['cmon']['mysql_port'] = 3306
default['cmon']['mysql_datadir'] = "/var/lib/mysql"
default['mysql']['root_password'] = "password"
default['cmon']['mysql_bin'] = "/usr/bin/mysql"
default['sql']['cmon_schema'] = "/usr/share/cmon/cmon_db.sql"
default['sql']['cmon_data'] = "/usr/share/cmon/cmon_data.sql"
default['sql']['cc_schema'] = "#{apache['wwwroot']}/clustercontrol/sql/dc-schema.sql"

default['cmonapi']['bootstrap']	= "#{apache['wwwroot']}/cmonapi/config/bootstrap.php"
default['cmonapi']['database'] = "#{apache['wwwroot']}/cmonapi/config/database.php"
default['ccui']['bootstrap'] = "#{apache['wwwroot']}/clustercontrol/bootstrap.php"
