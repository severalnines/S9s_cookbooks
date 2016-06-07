#
# Cookbook Name:: clustercontrol
# Recipe:: default
#
# Copyright 2014, Severalnines AB
#
# All rights reserved - Do Not Redistribute
#

cc_config = data_bag_item('clustercontrol','config')

node.set['api_token'] = cc_config['clustercontrol_api_token']
node.set['cmon']['rpc_key'] = cc_config['clustercontrol_api_token']
node.set['cmon']['mysql_password'] = cc_config['cmon_password']
node.set['cmon']['mysql_root_password'] = cc_config['mysql_root_password']
node.set['cmon']['mysql_port'] = cc_config['cmon_port']
node.set['mysql']['root_password'] = cc_config['mysql_root_password']
node.set['ssh_user'] = cc_config['ssh_user']
node.set['user_home'] = cc_config['user_home']

mysql_flag = "#{node['user_home']}/.mysql_installed"
cc_flag = "#{node['user_home']}/.cc_installed"

case node['platform_family']
when 'rhel', 'fedora'
	execute "setup-keyring" do
		command "rpm --import http://repo.severalnines.com/severalnines-repos.asc"
		action :run
	end
when 'debian'
	execute "setup-keyring" do
		command "wget http://repo.severalnines.com/severalnines-repos.asc -O- | apt-key add -"
		action :run
	end
end

template "#{node['repo_path']}/#{node['repo_file']}" do
	mode '0644'
	owner 'root'
	group 'root'
	source "#{node['repo_file']}.erb"
end

execute "update-repository" do
	command "#{node['update_repo']}"
	action :run
end

# install required packages
case node['platform_family']
when 'debian'
  packages = %w{apache2 libapache2-mod-php5 php5-common php5-mysql php5-gd php5-ldap php5-json php5-curl dnsutils curl mailutils wget mysql-client mysql-server clustercontrol-controller clustercontrol clustercontrol-cmonapi clustercontrol-nodejs}
  packages.each do |name|
    package name do
        Chef::Log.info "Installing #{name}"
    	action :install
    	options "--force-yes"
    end
  end
when 'rhel'
  if node['platform_version'].to_f < 7
    packages = %w{httpd php php-mysql php-ldap php-gd mod_ssl openssl bind-utils nc curl cronie mailx wget mysql mysql-server clustercontrol-controller clustercontrol clustercontrol-cmonapi clustercontrol-nodejs}
  else
    packages = %w{httpd php php-mysql php-ldap php-gd mod_ssl openssl bind-utils nc curl cronie mailx wget mariadb mariadb-server clustercontrol-controller clustercontrol clustercontrol-cmonapi clustercontrol-nodejs}
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
	action [ :enable, :restart ]
end

directory "#{node['user_home']}/.ssh" do
  owner "#{node['ssh_user']}"
  group "#{node['ssh_user']}"
  mode '0700'
  action :create
end

cookbook_file "id_rsa" do
	path "#{node['ssh_key']}"
	mode "0600"
	owner "#{node['ssh_user']}"
	group "#{node['ssh_user']}"
	action :create_if_missing
end

cookbook_file "id_rsa.pub" do
	path "#{node['ssh_key']}.pub"
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
end

if platform_family?("debian")
	execute "enable-modules-site" do
		command "a2enmod rewrite ssl; a2ensite #{node['apache']['ssl_vhost']}"
		action :run
	end
end

bash "configure-web-app" do
	user "root"
	code <<-EOH
		sed -i 's|AllowOverride None|AllowOverride All|g' #{node['apache']['config']}
		sed -i 's|AllowOverride None|AllowOverride All|g' #{node['apache']['ssl_config']}
		mkdir -p #{node['apache']['wwwroot']}/cmon/upload
		cp -f #{node['apache']['wwwroot']}/cmonapi/ssl/server.crt #{node['apache']['cert_file']}
		cp -f #{node['apache']['wwwroot']}/cmonapi/ssl/server.key #{node['apache']['key_file']}
		rm -rf #{node['apache']['wwwroot']}/cmonapi/ssl
		cp -f #{node['apache']['wwwroot']}/cmonapi/config/bootstrap.php.default #{node['cmonapi']['bootstrap']}
		cp -f #{node['apache']['wwwroot']}/cmonapi/config/database.php.default #{node['cmonapi']['database']}
		cp -f #{node['apache']['wwwroot']}/clustercontrol/bootstrap.php.default #{node['ccui']['bootstrap']}
		sed -i '#{node['apache']['cert_regex']} #{node['apache']['cert_file']}|g' #{node['apache']['ssl_config']}
		sed -i '#{node['apache']['key_regex']} #{node['apache']['key_file']}|g' #{node['apache']['ssl_config']}
		sed -i 's|GENERATED_CMON_TOKEN|#{node['api_token']}|g' #{node['cmonapi']['bootstrap']}
		sed -i 's|clustercontrol.severalnines.com|#{node['ipaddress']}\/clustercontrol|g' #{node['cmonapi']['bootstrap']}
		sed -i 's|MYSQL_PASSWORD|#{node['cmon']['mysql_password']}|g' #{node['cmonapi']['database']}
		sed -i 's|MYSQL_PORT|#{node['cmon']['mysql_port']}|g' #{node['cmonapi']['database']}
		sed -i 's|DBPASS|#{node['cmon']['mysql_password']}|g' #{node['ccui']['bootstrap']}
		sed -i 's|DBPORT|#{node['cmon']['mysql_port']}|g' #{node['ccui']['bootstrap']}
		sed -i 's|RPCTOKEN|#{node['cmon']['rpc_key']}|g' #{node['ccui']['bootstrap']}
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/cmon
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/cmonapi
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/clustercontrol
		cat #{node['user_home']}/.ssh/id_rsa.pub >> #{node['user_home']}/.ssh/authorized_keys
		chmod 600 #{node['user_home']}/.ssh/authorized_keys
	EOH
	notifies :restart, resources(:service => "#{node['apache']['service_name']}"), :immediately
end

service "cmon" do
	action :nothing
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

execute "cc-flag" do
	command "touch #{cc_flag}"
	action :run
	not_if { FileTest.exists?("#{cc_flag}") }
end
