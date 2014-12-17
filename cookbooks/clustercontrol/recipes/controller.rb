#
# Cookbook Name:: clustercontrol
# Recipe:: default
#
# Copyright 2014, Severalnines AB
#
# All rights reserved - Do Not Redistribute
#

cc_config = data_bag_item('clustercontrol','config')

node.set['cluster_type'] = cc_config['cluster_type']
node.set['api_token'] = cc_config['clustercontrol_api_token']
node.set['email_address'] = cc_config['email_address']
node.set['ssh_user'] = cc_config['ssh_user']
node.set['ssh_port'] = cc_config['ssh_port']
if "#{node['ssh_user']}" == "root"
	node.set['user_home'] = "/root"
else
	node.set['user_home'] = "/home/#{node['ssh_user']}"
end
node.set['ssh_key'] = "#{node['user_home']}/.ssh/id_rsa"
node.set['sudo_password'] = cc_config['sudo_password']
node.set['cmon']['mysql_password'] = cc_config['cmon_password']
node.set['cmon']['mysql_server_addresses'] = cc_config['mysql_server_addresses']
node.set['cmon']['datanode_addresses'] = cc_config['datanode_addresses']
node.set['cmon']['mgmnode_addresses'] = cc_config['mgmnode_addresses']
node.set['cmon']['ndb_connectstring'] = cc_config['ndb_connectstring']
node.set['cmon']['mongodb_server_addresses'] = cc_config['mongodb_server_addresses']
node.set['cmon']['mongoarbiter_server_addresses'] = cc_config['mongoarbiter_server_addresses']
node.set['cmon']['mongocfg_server_addresses'] = cc_config['mongocfg_server_addresses']
node.set['cmon']['mongos_server_addresses'] = cc_config['mongos_server_addresses']
node.set['mysql']['vendor'] = cc_config['vendor']

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
packages = node['packages']
packages.each do |name|
  package name do
  	Chef::Log.info "Installing #{name}"
    action :install
    #options "--force-yes"
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

bash "ssh-keyscan-nodes" do
	user "root"
	code <<-EOH
	if [ #{node['cluster_type']} != "mongodb" ] || [ #{node['cluster_type']} != "mysqlcluster" ]; then
		all_hosts=$(echo "#{node['ipaddress']} #{node['cmon']['mysql_server_addresses']}" | tr ',' ' ')
	elif [ #{node['cluster_type']} == "mysqlcluster" ]; then
		db_hosts=$(echo "#{node['ipaddress']} #{node['cmon']['mysql_server_addresses']} #{node['cmon']['mgmnode_addresses']} #{node['cmon']['datanode_addresses']}" | tr ',' ' ')
		all_hosts=$(echo "${db_hosts[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	else
		db_hosts=$(echo "#{node['ipaddress']} #{node['cmon']['mongodb_server_addresses']} #{node['cmon']['mongoarbiter_server_addresses']} #{node['cmon']['mongocfg_server_addresses']} #{node['cmon']['mongos_server_addresses']}"  | tr ',' ' ')
		all_hosts=$(echo "${db_hosts[@]}" | tr ' ' '\n' | sort -u | sed 's|:.*||g' | tr '\n' ' ')
	fi
	for h in $all_hosts
	do
		ssh-keyscan -t rsa $h >> #{node['user_home']}/.ssh/known_hosts
	done
	cat #{node['ssh_key']}.pub >> #{node['user_home']}/.ssh/authorized_keys
	EOH
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

if platform?("ubuntu")
	if node['platform_version'].to_f >= 14.04
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
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/cmon
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/cmonapi
		chown -Rf #{node['apache']['user']}:#{node['apache']['user']} #{node['apache']['wwwroot']}/clustercontrol
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
	mode "0644"
	notifies :restart, resources(:service => "cmon")
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
