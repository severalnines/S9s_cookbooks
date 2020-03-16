#
# Cookbook Name:: clustercontrol
# Recipe:: default
#
# Copyright 2018, Severalnines AB
#
# All rights reserved - Do Not Redistribute
#

cc_config = data_bag_item('clustercontrol','config')

node.override['api_token'] = cc_config['clustercontrol_api_token']
node.override['cmon']['rpc_key'] = cc_config['clustercontrol_api_token']
node.override['cmon']['mysql_password'] = cc_config['cmon_password']
node.override['cmon']['mysql_root_password'] = cc_config['mysql_root_password']
node.override['mysql']['root_password'] = cc_config['mysql_root_password']
node.override['ssh_user'] = cc_config['cmon_ssh_user']
node.override['ssh_user_home'] = cc_config['cmon_user_home']

mysql_flag = "#{node['ssh_user_home']}/.mysql_installed"
cc_flag = "#{node['ssh_user_home']}/.cc_installed"

case node['platform_family']
when 'rhel', 'fedora'
	execute "disable-selinux" do
		command "setenforce 0"
		only_if "sestatus | grep 'Current mode' | awk {'print $3'} | grep enforcing"
		action :run
	end
	execute "set-selinux-permissive" do
		command "sed -i 's|^SELINUX.*|SELINUX=permissive|g' /etc/selinux/config"
		only_if "grep '^SELINUX=enforcing' /etc/selinux/config"
		action :run
	end
	yum_repository 's9s-repo' do
		baseurl "http://repo.severalnines.com/rpm/os/x86_64"
		description "Severalnines Release Repository"
		gpgkey "http://repo.severalnines.com/severalnines-repos.asc"
		action :create
	end
	yum_repository 's9s-tools' do
		baseurl "http://repo.severalnines.com/s9s-tools/#{node['platform_family'].upcase}_#{node['platform_version'].to_i}/"
		description "s9s-tools (#{node['platform_family'].upcase}_#{node['platform_version'].to_i})"
		gpgkey "http://repo.severalnines.com/s9s-tools/#{node['platform_family'].upcase}_#{node['platform_version'].to_i}/repodata/repomd.xml.key"
		action :create
	end

when 'debian'
	apt_repository "s9s-repo" do
		uri "http://repo.severalnines.com/deb"
		components ['ubuntu','main']
		arch "amd64"
		key "http://repo.severalnines.com/severalnines-repos.asc"
		distribution ''
		action :add
	end

	apt_repository "s9s-tools" do
		uri "http://repo.severalnines.com/s9s-tools/#{node['lsb']['codename']}/"
		key "http://repo.severalnines.com/s9s-tools/#{node['lsb']['codename']}/Release.key"
		components ['./']
		distribution ''
		action :add
	end

	apt_update
end

# install required packages
case node['platform_family']
when 'debian'
  if (node['platform'] == 'debian' && node['platform_version'].to_f >= 10)
    packages = %w{apache2 libapache2-mod-php php-common php-mysql php-gd php-ldap php-json php-curl php-xml net-tools dnsutils curl mailutils wget mariadb-client mariadb-server clustercontrol-controller clustercontrol clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
  elsif (node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 16.04 || node['platform'] == 'debian' && node['platform_version'].to_f >= 9)
    packages = %w{apache2 libapache2-mod-php php-common php-mysql php-gd php-ldap php-json php-curl php-xml net-tools dnsutils curl mailutils wget mysql-client mysql-server clustercontrol-controller clustercontrol clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
  else
    packages = %w{apache2 libapache2-mod-php5 php5-common php5-mysql php5-gd php5-ldap php5-json php5-curl net-tools dnsutils curl mailutils wget mysql-client mysql-server clustercontrol-controller clustercontrol clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
  end
  packages.each do |name|
    package name do
        Chef::Log.info "Installing #{name}"
    	action :install
    	options "--force-yes"
    end
  end
when 'rhel'
  if node['platform_version'].to_f < 7
    packages = %w{httpd php php-mysql php-ldap php-gd php-json php-xml ntp ntpdate mod_ssl openssl bind-utils nc curl cronie mailx wget mysql mysql-server clustercontrol-controller clustercontrol clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
  elsif node['platform_version'].to_i == 7
    packages = %w{httpd php php-mysql php-ldap php-gd php-json php-xml ntp ntpdate mod_ssl openssl net-tools bind-utils nc curl cronie mailx wget mariadb mariadb-server clustercontrol-controller clustercontrol clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
  else # RHEL 8 and later
    packages = %w{httpd php php-mysqlnd php-ldap php-gd php-json php-xml ntp ntpdate mod_ssl openssl net-tools bind-utils nc curl cronie mailx wget mariadb mariadb-server clustercontrol-controller clustercontrol clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
  end
  packages.each do |name|
    package name do
        Chef::Log.info "Installing #{name}"
    	action :install
    end
  end
end

# restart services after installed
service "#{node['apache']['service_name']}" do
	action [ :enable, :restart ]
end

service "#{node['mysql']['service_name']}" do
	action :stop
end

execute 'sleep 10'

service "#{node['mysql']['service_name']}" do
        action [ :enable, :start ]
end

directory "#{node['ssh_user_home']}/.ssh" do
  owner "#{node['ssh_user']}"
  group "#{node['ssh_user']}"
  mode '0700'
  action :create
end

cookbook_file "id_rsa" do
	path "#{node['ssh_user_home']}/.ssh/id_rsa"
	mode "0600"
	owner "#{node['ssh_user']}"
	group "#{node['ssh_user']}"
	action :create_if_missing
end

cookbook_file "id_rsa.pub" do
	path "#{node['ssh_user_home']}/.ssh/id_rsa.pub"
	mode "0600"
	owner "#{node['ssh_user']}"
	group "#{node['ssh_user']}"
	action :create_if_missing
end

service "#{node['mysql']['service_name']}" do
	action :stop
end

template "#{node['mysql']['conf_file']}" do
	path "#{node['mysql']['conf_file']}"
	source "my.cnf.erb"
	owner "mysql"
	group "mysql"
	mode "0644"
end

execute "purge-innodb-logfiles" do
	command "rm #{node['cmon']['mysql_datadir']}/ib_logfile*"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

service "mysql" do
	service_name node['mysql']['service_name']
	supports :stop => true, :start => true, :restart => true, :reload => true
	action :start
	subscribes :restart, resources(:template => "#{node['mysql']['conf_file']}")
end

service "reload-mysql-cnf" do
	service_name node['mysql']['service_name']
	supports :stop => true, :start => true, :restart => true, :reload => true
	action :restart
	not_if { FileTest.exists?("#{mysql_flag}") }
end

bash "secure-mysql" do
  user "root"
  code <<-EOH
  #{node['cmon']['mysql_bin']} -uroot -e "UPDATE mysql.user SET Password=PASSWORD('#{node['mysql']['root_password']}') WHERE User='root'"
  #{node['cmon']['mysql_bin']} -uroot -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
  #{node['cmon']['mysql_bin']} -uroot -e "DROP DATABASE test; DELETE FROM mysql.db WHERE DB='test' OR Db='test\\_%;"
  #{node['cmon']['mysql_bin']} -uroot -e "FLUSH PRIVILEGES"
  EOH
  not_if { FileTest.exists?("#{mysql_flag}") }
end

execute "cmon-import-structure" do
	command "#{node['cmon']['mysql_bin']} -uroot -p#{node['mysql']['root_password']} < #{node['sql']['cmon_schema']}"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

execute "cmon-import-data" do
	command "#{node['cmon']['mysql_bin']} -uroot -p#{node['mysql']['root_password']} < #{node['sql']['cmon_data']}"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

execute "cc-import-structure-data" do
	command "#{node['cmon']['mysql_bin']} -uroot -p#{node['mysql']['root_password']} < #{node['sql']['cc_schema']}"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

configure_cmon_db_sql = "#{Chef::Config[:file_cache_path]}/configure_cmon_db.sql"

execute "configure-cmon-db" do
	command "#{node['cmon']['mysql_bin']} -uroot -p#{node['mysql']['root_password']} < #{configure_cmon_db_sql}"
	action :nothing
	not_if { FileTest.exists?("#{mysql_flag}") }
end

template "configure_cmon_db.sql" do
	path "#{configure_cmon_db_sql}"
	source "configure_cmon_db.sql.erb"
	owner "root"
	group "root"
	mode "0644"
	notifies :run, resources(:execute => "configure-cmon-db"), :immediately
end

execute "mysql-flag" do
	command "touch #{mysql_flag}"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

service "#{node['apache']['service_name']}" do
	action :nothing
end

if platform?("ubuntu","debian")
	if (node["platform"] == "ubuntu" && node['platform_version'].to_f >= 14.04) || (node["platform"] == "debian" && node['platform_version'].to_f >= 8)
		bash "pre-configure-web-app" do
			user "root"
			code <<-EOH
				cp -f #{node['apache']['wwwroot']}/clustercontrol/app/tools/apache2/s9s.conf /etc/apache2/sites-available/
				cp -f #{node['apache']['wwwroot']}/clustercontrol/app/tools/apache2/s9s-ssl.conf /etc/apache2/sites-available/
				rm -f /etc/apache2/sites-enabled/000-default.conf
				rm -f /etc/apache2/sites-enabled/default-ssl.conf
				rm -f /etc/apache2/sites-enabled/001-default-ssl.conf
				ln -sfn #{node['apache']['config']} /etc/apache2/sites-enabled/001-s9s.conf
				ln -sfn #{node['apache']['ssl_config']} /etc/apache2/sites-enabled/001-s9s-ssl.conf
			EOH
		end
	end
elsif platform_family?("rhel")
	bash "pre-configure-web-app" do
		user "root"
		code <<-EOH
			cp -f #{node['apache']['wwwroot']}/clustercontrol/app/tools/apache2/s9s.conf /etc/httpd/conf.d/
			cp -f #{node['apache']['wwwroot']}/clustercontrol/app/tools/apache2/s9s-ssl.conf /etc/httpd/conf.d/
		EOH
	end
end

if platform_family?("debian")
	execute "enable-modules-site" do
		command "a2enmod rewrite ssl proxy proxy_http proxy_wstunnel; a2ensite #{node['apache']['ssl_vhost']}"
		action :run
		notifies :restart, resources(:service => "#{node['apache']['service_name']}"), :immediately
	end
end

bash "configure-web-app" do
	user "root"
	code <<-EOH
		mkdir -p #{node['apache']['wwwroot']}/cmon/upload
		cp -f #{node['apache']['wwwroot']}/clustercontrol/ssl/server.crt #{node['apache']['cert_file']}
		cp -f #{node['apache']['wwwroot']}/clustercontrol/ssl/server.key #{node['apache']['key_file']}
		rm -rf #{node['apache']['wwwroot']}/clustercontrol/ssl
		cp -f #{node['apache']['wwwroot']}/clustercontrol/bootstrap.php.default #{node['ccui']['bootstrap']}
		sed -i '#{node['apache']['cert_regex']} #{node['apache']['cert_file']}|g' #{node['apache']['ssl_config']}
		sed -i '#{node['apache']['key_regex']} #{node['apache']['key_file']}|g' #{node['apache']['ssl_config']}
		sed -i 's|DBPASS|#{node['cmon']['mysql_password']}|g' #{node['ccui']['bootstrap']}
		sed -i 's|DBPORT|#{node['cmon']['mysql_port']}|g' #{node['ccui']['bootstrap']}
		sed -i 's|RPCTOKEN|#{node['cmon']['rpc_key']}|g' #{node['ccui']['bootstrap']}
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/cmon
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/clustercontrol
		cat #{node['ssh_user_home']}/.ssh/id_rsa.pub >> #{node['ssh_user_home']}/.ssh/authorized_keys
		chmod 600 #{node['ssh_user_home']}/.ssh/authorized_keys
	EOH
	notifies :restart, resources(:service => "#{node['apache']['service_name']}"), :immediately
end

service "cmon" do
	action :nothing
end

template "cmon.default" do
	path "/etc/default/cmon"
	source "cmon.default.erb"
	owner "root"
	group "root"
	mode "0600"
	notifies :restart, resources(:service => "cmon")
end

template "cmon.cnf" do
	path "/etc/cmon.cnf"
	source "cmon.cnf.erb"
	owner "root"
	group "root"
	mode "0600"
	notifies :restart, resources(:service => "cmon")
end

file "#{node['apache']['wwwroot']}/clustercontrol/bootstrap.php" do
	owner "#{node['apache']['user']}"
	group "#{node['apache']['user']}"
end

service "cmon" do
	supports :restart => true, :start => true, :stop => true, :reload => true
	action [ :enable, :start ]
end

service "cmon-ssh" do
        supports :restart => true, :start => true, :stop => true, :reload => true
        action [ :enable, :start ]
end

service "cmon-events" do
        supports :restart => true, :start => true, :stop => true, :reload => true
        action [ :enable, :start ]
end

service "cmon-cloud" do
        supports :restart => true, :start => true, :stop => true, :reload => true
        action [ :enable, :start ]
end

execute "cc-flag" do
	command "touch #{cc_flag}"
	action :run
	not_if { FileTest.exists?("#{cc_flag}") }
end
