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
node.override['controller_id'] = cc_config['clustercontrol_controller_id'] 
node.override['cmon']['rpc_key'] = cc_config['clustercontrol_api_token'] 
node.override['cmon']['mysql_password'] = cc_config['cmon_password'] 
node.override['cmon']['mysql_root_password'] = cc_config['mysql_root_password'] 
node.override['mysql']['root_password'] = cc_config['mysql_root_password'] 
node.override['ssh_user'] = cc_config['cmon_ssh_user'] 
node.override['ssh_user_home'] = cc_config['cmon_user_home']
if (cc_config['cmon_server_host'] == "" or cc_config['cmon_server_host'] == nil)
  node.override['apache']['server_hostname'] = node['fqdn']
else
  node.override['apache']['server_hostname'] = cc_config['cmon_server_host']
end

## global params
mysql_flag = "#{node['ssh_user_home']}/.mysql_installed"
cc_flag = "#{node['ssh_user_home']}/.cc_installed"
cmon_grants_flag = "/tmp/mysqld_ver.txt"
ccsetup_email = node['ccsetup_email']
cmon_container = node['cmon']['container']


## global apache/web params
cert_file = ""
key_file = ""
pkg_options = ""
wwwroot = "/var/www/html"
ccv1_webroot_directory = "/var/www/html/clustercontrol"
ccv2_webroot_directory = "#{wwwroot}/clustercontrol2/"
apache_s9s_source_config_ccv1_file = "#{ccv1_webroot_directory}/app/tools/apache2/s9s.conf"
apache_s9s_source_config_ccv1_ssl_file = "#{ccv1_webroot_directory}/app/tools/apache2/s9s-ssl.conf"
apache_server_hostname = node['apache']['server_hostname']

## global mysql variables
mysql_bin_path = "/usr/bin/mysql"
mysqld_bin_path = "/usr/sbin/mysqld"
mysql_root_password = node['mysql']['root_password']
mysql_data_dir = "/var/lib/mysql"
mysql_base_dir = "/usr"
mysql_port = node['cmon']['mysql_port']
  
## cc/cmon global variables
cmon_mysql_port = node['cmon']['mysql_port']
cmon_mysql_hostname = node['cmon']['mysql_hostname']
cmon_mysql_password = node['cmon']['mysql_root_password']
cmon_hostname = cc_config['cmon_server_host']
cmon_rpc_key = node['api_token']
controller_id = node['controller_id']
cmon_os_user = node['cmon_ssh_user']
cmon_os_user_home_dir = node['ssh_user_home']
    
cmon_mysql_password = node['cmon']['mysql_password']
cmon_sql_cmon_schema = "/usr/share/cmon/cmon_db.sql"
cmon_sql_cmon_data = "/usr/share/cmon/cmon_data.sql"
cmon_www_ccv1_sql_directory = "#{wwwroot}/clustercontrol/sql"
cmon_sql_dc_schema = "#{cmon_www_ccv1_sql_directory}/dc-schema.sql"
cmon_www_bootstrap_file = "#{wwwroot}/clustercontrol/bootstrap.php"

output="#{Chef::JSONCompat.to_json_pretty(node.to_hash)}"
file '/tmp/node.json' do
  content "#{node['platform_family']}"
end

case node['platform_family']
  when 'rhel'

    if node['platform_version'].to_f < 7
      raise "S9S Chef Cookbooks does not support RHEL/CentOS/Rocky/Alma Linux versions anymore"
    end

  	if node['platform_version'].to_f < 7
  		mysql_service_name = "mysqld"
  	else
  		mysql_service_name = "mariadb"
  	end
  
    ## setup variables for web specifics
  	apache_log_dir = "/var/log/httpd"
    apache_config_directory = "/etc/httpd"
  	apache_conf_file = "#{apache_config_directory}/conf/httpd.conf"
  	apache_security_conf_file = "#{apache_config_directory}/conf.d/security.conf"
  	apache_s9s_ccv1_conf_src_file = "#{apache_config_directory}/conf.d/s9s.conf"
  	apache_s9s_ccv1_ssl_conf_src_file = "#{apache_config_directory}/conf.d/s9s-ssl.conf"
  	apache_s9s_ccv2_frontend_conf_src_file = "#{apache_config_directory}/conf.d/cc-frontend.conf"
  	apache_s9s_ccv2_proxy_conf_src_file = "#{apache_config_directory}/conf.d/cc-proxy.conf"
  
  	cert_file        = '/etc/pki/tls/certs/s9server.crt'
  	key_file         = '/etc/pki/tls/private/s9server.key'
  	apache_user      = 'apache'
  	apache_service_name   = 'httpd'
  	mysql_cnf_path   = '/etc/my.cnf'    
    mysql_socket_path = "/var/lib/mysql/mysql.sock"
    
  
  	execute "disable-selinux" do
  		command "setenforce 0"
  		only_if "sestatus | grep 'Current mode' | awk {'print $3'} | grep enforcing"
  		action :run
  	end
    
  	execute "disable-firewalld" do
  		command "systemctl stop firewalld"
  		only_if "ps axufww|grep firewall[d]"
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

    if node['platform_version'].to_i == 7
      packages = %w{httpd php php-mysql php-ldap php-gd php-json php-xml ntp ntpdate mod_ssl openssl net-tools bind-utils nc curl cronie mailx wget mariadb mariadb-server clustercontrol-controller clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
    else # RHEL 8 and later
      packages = %w{httpd php php-mysqlnd php-ldap php-gd php-json php-xml mod_ssl openssl net-tools bind-utils nc curl cronie mailx wget mariadb mariadb-server clustercontrol-controller clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
    end
  
    if (node['only_cc_v2'])
      packages.push("clustercontrol2")
    else 
      packages.push("clustercontrol")
      packages.push("clustercontrol2")
    end
    
  when 'debian', 'ubuntu'
  
    ## setup variables for web specifics
  	apache_log_dir = "/var/log/apache2/"
    apache_config_directory = "/etc/apache2"
    apache_config_sites_available_directory = "#{apache_config_directory}/sites-available"
    apache_config_sites_enabled_directory = "#{apache_config_directory}/sites-enabled"
  	apache_security_conf_file = "#{apache_config_directory}/conf-available/security.conf"
  	apache_security_target_conf_file = "#{apache_config_directory}/conf-enabled/security.conf"
  	apache_mods_header_file = "#{apache_config_directory}/mods-available/headers.load"
  	apache_mods_header_target_file = "#{apache_config_directory}/mods-enabled/headers.load"
  	apache_conf_file = "#{apache_config_directory}/apache2.conf"
    
  	apache_s9s_ccv1_conf_src_file = "#{apache_config_sites_available_directory}/s9s.conf"
  	apache_s9s_ccv1_ssl_conf_src_file = "#{apache_config_sites_available_directory}/s9s-ssl.conf"
  	apache_s9s_ccv2_frontend_conf_src_file = "#{apache_config_sites_available_directory}/cc-frontend.conf"
  	apache_s9s_ccv2_proxy_conf_src_file = "#{apache_config_sites_available_directory}/cc-proxy.conf"
    
    
  	apache_s9s_ccv1_conf_target_file = "#{apache_config_sites_enabled_directory}/001-s9s.conf"
  	apache_s9s_ccv1_ssl_conf_target_file = "#{apache_config_sites_enabled_directory}/001-s9s-ssl.conf"
  	apache_s9s_ccv2_frontend_conf_target_file = "#{apache_config_sites_enabled_directory}/cc-frontend.conf"
  	apache_s9s_ccv2_proxy_conf_target_file = "#{apache_config_sites_enabled_directory}/cc-proxy.conf"

  	cert_file        = '/etc/ssl/certs/s9server.crt'
  	key_file         = '/etc/ssl/private/s9server.key'
  	apache_user      = 'www-data'
  	apache_service_name   = 'apache2'
  	mysql_cnf_path        = '/etc/mysql/my.cnf'
    mysql_socket_path = "/var/run/mysqld/mysqld.sock"
  
  	repo_source      = '/etc/apt/sources.list.d/s9s-repo.list'
  	repo_tools_src   = '/etc/apt/sources.list.d/s9s-tools.list'
    

  	repo_path = "/etc/apt/sources.list.d"
    # s9s_repo_file = "s9s-tools.list"
    # update_repo = "apt-get update"
    
    # if (node['platform'] == "ubuntu" && node['platform_version'].to_f == 12.04 )
    #   s9s_repo_url = 'http://repo.severalnines.com/s9s-tools/precise/'
    #   s9s_repo_key_url = 'http://repo.severalnines.com/s9s-tools/precise/Release.key'
    # elsif (node['platform'] == "ubuntu" && node['platform_version'].to_f == 14.04 )
    #   s9s_repo_url = 'http://repo.severalnines.com/s9s-tools/trusty/'
    #   s9s_repo_key_url = 'http://repo.severalnines.com/s9s-tools/trusty/Release.key'
    # elsif (node['platform'] == "ubuntu" && node['platform_version'].to_f == 16.04 )
    #   s9s_repo_url = 'http://repo.severalnines.com/s9s-tools/xenial/'
    #   s9s_repo_key_url = 'http://repo.severalnines.com/s9s-tools/xenial/Release.key'
    # elsif (node['platform'] == "ubuntu" && node['platform_version'].to_f == 17.04 )
    #   s9s_repo_url  = 'http://repo.severalnines.com/s9s-tools/zesty/'
    #   s9s_repo_key_url = 'http://repo.severalnines.com/s9s-tools/zesty/Release.key'
    # elsif (node['platform'] == "ubuntu" && node['platform_version'].to_f == 18.04 )
    #   s9s_repo_url  = 'http://repo.severalnines.com/s9s-tools/bionic/'
    #   s9s_repo_key_url  = 'http://repo.severalnines.com/s9s-tools/bionic/Release.key'
    # elsif (node['platform'] == "debian" && node['platform_version'].to_f >= 7 && node['platform_version'].to_f < 8 )
    #   s9s_repo_url  = 'http://repo.severalnines.com/s9s-tools/wheezy/'
    #   s9s_repo_key_url  = 'http://repo.severalnines.com/s9s-tools/wheezy/Release.key'
    # elsif (node['platform'] == "debian" && node['platform_version'].to_f >= 8 && node['platform_version'].to_f < 9 )
    #   s9s_repo_url  = 'http://repo.severalnines.com/s9s-tools/jessie/'
    #   s9s_repo_key_url  = 'http://repo.severalnines.com/s9s-tools/jessie/Release.key'
    # elsif (node['platform'] == "debian" && node['platform_version'].to_f >= 9 )
    #   s9s_repo_url  = 'http://repo.severalnines.com/s9s-tools/stretch/'
    #   s9s_repo_key_url  = 'http://repo.severalnines.com/s9s-tools/stretch/Release.key'
    # end

  	apache_extra_opt = nil

		## apache_extra_opt = 'Require all granted' <- needed for suse linux
    
  	mysql_cnf_path = "/etc/mysql/my.cnf"
    mysql_service_name = "mysql"
    
	
  	apt_package 'install-gpg' do
  		package_name "gpg"
  		action :install
  	end
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
  

    if (node['platform'] == 'debian' && node['platform_version'].to_f >= 10)
      packages = %w{apache2 libapache2-mod-php php-common php-mysql php-gd php-ldap php-json php-curl php-xml net-tools dnsutils curl mailutils wget mariadb-client mariadb-server clustercontrol-controller clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
    elsif (node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 16.04 || node['platform'] == 'debian' && node['platform_version'].to_f >= 9)
      packages = %w{apache2 libapache2-mod-php php-common php-mysql php-gd php-ldap php-json php-curl php-xml net-tools dnsutils curl mailutils wget mysql-client mysql-server clustercontrol-controller clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
    else
      packages = %w{apache2 libapache2-mod-php5 php5-common php5-mysql php5-gd php5-ldap php5-json php5-curl net-tools dnsutils curl mailutils wget mysql-client mysql-server clustercontrol-controller clustercontrol-notifications clustercontrol-ssh clustercontrol-cloud clustercontrol-clud s9s-tools}
    end
  
    if (node['only_cc_v2'])
      packages.push("clustercontrol2")
    else 
      packages.push("clustercontrol")
      packages.push("clustercontrol2")
    end
  
    pkg_options = "--force-yes"
  
end

# install required packages
packages.each do |name|
  package name do
      Chef::Log.info "Installing #{name}"
      if (name == "clustercontrol")
        ## only install later once db trx below are done
      	action :nothing
      else
  	    action :install
      end
  	options "#{pkg_options}"
  end
end

execute "sleep-10" do
  command "sleep 10"
  action :nothing
end

# service "#{mysql_service_name}" do
#   action :stop
#   notifies :run, resources(:execute => "sleep-10"), :immediately
#   not_if { FileTest.exists?("#{mysql_flag}") }
# end

service "#{mysql_service_name}" do
  action [ :enable, :start ]
	not_if { FileTest.exists?("#{mysql_flag}") }
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

service "#{mysql_service_name}" do
	action :stop
	not_if { FileTest.exists?("#{mysql_flag}") }
end

template "#{mysql_cnf_path}" do
	path "#{mysql_cnf_path}"
	source "my.cnf.erb"
	owner "mysql"
	group "mysql"
	mode "0644"
  variables(
    :mysql_base_dir => mysql_base_dir,
    :mysql_data_dir => mysql_data_dir,
    :mysql_socket_path => mysql_socket_path
  )
end

# execute "purge-innodb-logfiles" do
#   command "rm #{node['cmon']['mysql_datadir']}/ib_logfile*"
#   action :run
#   not_if { FileTest.exists?("#{mysql_flag}") }
# end

# file "#{node['cmon']['mysql_datadir']}/ib_logfile*" do
#   action :delete
#   only_if { File.exist? "#{node['cmon']['mysql_datadir']}/ib_logfile*" }
# end


service "#{mysql_service_name}" do
	service_name "#{mysql_service_name}"
	supports :stop => true, :start => true, :restart => true, :reload => true
	action :start
	subscribes :restart, resources(:template => "#{mysql_cnf_path}")
	not_if { FileTest.exists?("#{mysql_flag}") }
end

# service "reload-mysql-cnf" do
#   service_name "#{mysql_service_name}"
#   supports :stop => true, :start => true, :restart => true, :reload => true
#   action :restart
#   not_if { FileTest.exists?("#{mysql_flag}") }
# end

bash "secure-mysql" do
  user "root"
  code <<-EOH
  #{mysql_bin_path} -uroot -e "UPDATE mysql.user SET authentication_string=PASSWORD('#{mysql_root_password}'), Password=PASSWORD('#{mysql_root_password}') WHERE User='root'"
  #{mysql_bin_path} -uroot -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
  #{mysql_bin_path} -uroot -e "DROP DATABASE test; DELETE FROM mysql.db WHERE DB='test' OR Db='test\\_%;"
  #{mysql_bin_path} -uroot -e "FLUSH PRIVILEGES"
  EOH
  not_if { FileTest.exists?("#{mysql_flag}") }
end

execute "cmon-import-structure" do
	command "#{mysql_bin_path} -uroot -p#{mysql_root_password} < #{cmon_sql_cmon_schema}"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

execute "cmon-import-data" do
	command "#{mysql_bin_path} -uroot -p#{mysql_root_password} < #{cmon_sql_cmon_data}"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

if (node['only_cc_v2'] == false)
  ## ccv1 and ccv2
  execute "cc-import-structure-data" do
  	command "#{mysql_bin_path} -uroot -p#{mysql_root_password} < #{cmon_sql_dc_schema}"
  	action :nothing
  	not_if { FileTest.exists?("#{mysql_flag}") }
  end
end


execute "cc-insert-api-key-to-dcps-schema" do
	command "#{mysql_bin_path} -uroot  -p#{mysql_root_password} dcps -e \"REPLACE INTO dcps.apis (id, company_id, user_id, url, token) VALUES (1,1,1,'http://127.0.0.1','#{cmon_rpc_key}');\""
  action :nothing
	not_if { FileTest.exists?("#{mysql_flag}") }
end

mysqld_ver = 0
configure_cmon_db_sql = "#{Chef::Config[:file_cache_path]}/configure_cmon_db.sql"

ruby_block "check_mysql_version" do
    block do
      #tricky way to load this Chef::Mixin::ShellOut utilities
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)  
      node.run_state['mysqld_ver'] = shell_out("#{mysqld_bin_path} --version|sed 's! \+! !g'|cut -d ' ' -f 4|cut -d '.' -f 1").stdout
      mysqld_ver = node.run_state['mysqld_ver']
      if node.run_state['mysqld_ver'].to_i == 8
        #log "executing inject to mysql 8"
        node.run_state['configure_cmon_db_sql_src'] = "configure_cmon_db_mysql8.sql.erb"
      else
        #log "executing inject to mysql <=8"
        node.run_state['configure_cmon_db_sql_src'] = "configure_cmon_db.sql.erb"
      end
    end
    if (node['only_cc_v2'])
      subscribes :run,  resources(:execute => "cmon-import-data")
    # else
    #   # subscribes :run,  resources(:execute => "cc-import-structure-data")
    end
end


file "#{cmon_grants_flag}" do
  content lazy {"#{node.run_state['mysqld_ver']}" + "#{node.run_state['configure_cmon_db_sql_src']}" }
  action :nothing
end

template "configure_cmon_db_mysql8.sql.erb" do
	path "#{configure_cmon_db_sql}"
  source lazy { "#{node.run_state['configure_cmon_db_sql_src']}" }
  # source "#{node.run_state['configure_cmon_db_sql_src']}"
  # source "configure_cmon_db_mysql8.sql.erb"
	owner "root"
	group "root"
	mode "0644"
  # not_if { FileTest.exists?("#{cc_flag}") }
  # not_if { shell_out("mysqladmin -ucmon -p#{cmon_mysql_password} -h#{cmon_mysql_hostname} -P#{cmon_mysql_port} ping 2>/dev/null") }
  # not_if { shell_out("mysql -ucmon -p#{cmon_mysql_password}  -P#{cmon_mysql_port} -e \"select 'PING' as pong;\" -Ns -h127.0.0.1 > /dev/null; return $?") }
  action :create_if_missing
  variables(
    :cmon_mysql_password => cmon_mysql_password,
    :cmon_hostname => cmon_hostname
  )
  # notifies :run, 'ruby_block[check_mysql_version]', :delayed
  # subscribes :install, 'package[clustercontrol]', :immediately
  # subscribes  :run, 'execute[cc-import-structure-data]', :immediately
end

execute "configure-cmon-db" do
	command "#{mysql_bin_path} -uroot -p#{mysql_root_password} < #{configure_cmon_db_sql}"
	action :nothing
  # not_if { FileTest.exists?("#{cc_flag}") }
  # not_if { shell_out("mysqladmin -ucmon -p#{cmon_mysql_password} -h#{cmon_mysql_hostname} -P#{cmon_mysql_port} ping 2>/dev/null") }
  # not_if "[[ $(mysql -ucmon -p#{cmon_mysql_password}  -P#{cmon_mysql_port} -e \"select 'PING' as pong;\" -Ns -h127.0.0.1 2> /dev/null); exit $? ]]"
  # not_if '[[ $(/usr/bin/mysql -uroot -pR00tP@55 -Nse "select count(1) from mysql.user where user=\"cmon\";" 2>/dev/null) -gt 0 ]]'
  not_if { FileTest.exists?("/tmp/mysqld_ver.txt") }
  notifies :create_if_missing, "file[#{cmon_grants_flag}]", :immediately
end

# if (node['only_cc_v2'] == false)
#   directory "#{cmon_www_ccv1_sql_directory}" do
#     recursive true
#     action :delete
#   end
# end

# restart services after installed
service "#{apache_service_name}" do
  # action [ :enable, :restart ]
	action :nothing # [ :enable, :restart ]
  # not_if { FileTest.exists?("#{cc_flag}") }
end

bash "pre-configure-web-app" do
	user "root"
  action :nothing
  if (node['only_cc_v2'] == false)
    ##ccv1 and ccv2 installation
    if platform_family?("debian")
    	if (node["platform"] == "ubuntu" && node['platform_version'].to_f >= 14.04) || (node["platform"] == "debian" && node['platform_version'].to_f >= 8)
        ## support only new and recent versions of ubuntu/debian
    			code <<-EOH
    				rm -f #{apache_config_directory}/sites-enabled/000-default.conf
    				rm -f #{apache_config_directory}/sites-enabled/default-ssl.conf
    				rm -f #{apache_config_directory}/sites-enabled/001-default-ssl.conf
    				rm -f #{apache_s9s_ccv1_conf_target_file} #{apache_s9s_ccv1_ssl_conf_target_file} #{apache_s9s_ccv2_frontend_conf_target_file} #{apache_s9s_ccv2_proxy_conf_target_file}
    				cp -f #{apache_s9s_source_config_ccv1_file} #{apache_config_sites_available_directory}/
    				cp -f #{apache_s9s_source_config_ccv1_ssl_file} #{apache_config_sites_available_directory}/
    				ln -sf #{apache_s9s_ccv1_conf_src_file} #{apache_s9s_ccv1_conf_target_file}
    				ln -sf #{apache_s9s_ccv1_ssl_conf_src_file} #{apache_s9s_ccv1_ssl_conf_target_file}
    				ln -sf #{apache_s9s_ccv2_frontend_conf_src_file} #{apache_s9s_ccv2_frontend_conf_target_file}
    				ln -sf #{apache_s9s_ccv2_proxy_conf_src_file} #{apache_s9s_ccv2_proxy_conf_target_file}

            sed -ibak "s|AllowOverride None|AllowOverride All|g" #{apache_s9s_ccv1_conf_src_file}
            sed -ibak "s|AllowOverride None|AllowOverride All|g" #{apache_s9s_ccv1_ssl_conf_src_file}

            # Apache's default cert's lifespan is  1-10y depending on distro
            sed -ibak "s|^[ \t]*SSLCertificateFile.*|	        SSLCertificateFile #{cert_file}|g" #{apache_s9s_ccv1_ssl_conf_src_file}
            sed -ibak "s|^[ \t]*SSLCertificateKeyFile.*|	        SSLCertificateKeyFile #{key_file}|g" #{apache_s9s_ccv1_ssl_conf_src_file}
            
    			EOH
    	end
    elsif platform_family?("rhel")
        code <<-EOH

          cp -f #{apache_s9s_source_config_ccv1_file} #{apache_s9s_ccv1_conf_src_file}
          cp -f #{apache_s9s_source_config_ccv1_ssl_file} #{apache_s9s_ccv1_ssl_conf_src_file}
          
          sed -ibak "s|AllowOverride None|AllowOverride All|g" #{apache_s9s_ccv1_conf_src_file}
          sed -ibak "s|AllowOverride None|AllowOverride All|g" #{apache_s9s_ccv1_ssl_conf_src_file}

          # Apache's default cert's lifespan is  1-10y depending on distro
          sed -ibak "s|^[ \t]*SSLCertificateFile.*|	        SSLCertificateFile #{cert_file}|g" #{apache_s9s_ccv1_ssl_conf_src_file}
          sed -ibak "s|^[ \t]*SSLCertificateKeyFile.*|	        SSLCertificateKeyFile #{key_file}|g" #{apache_s9s_ccv1_ssl_conf_src_file}
          sed -ibak "s|^[ \t]*#SSLCertificateChainFile.*|	        SSLCertificateChainFile #{cert_file}|g" #{apache_s9s_ccv1_ssl_conf_src_file}
        EOH
    end
  else
    ## only ccv2
    if platform_family?("debian")
    	if (node["platform"] == "ubuntu" && node['platform_version'].to_f >= 14.04) || (node["platform"] == "debian" && node['platform_version'].to_f >= 8)
        ## support only new and recent versions of ubuntu/debian
    			code <<-EOH
    				rm -f #{apache_config_sites_enabled_directory}/000-default.conf
    				rm -f #{apache_config_sites_enabled_directory}/default-ssl.conf
    				rm -f #{apache_config_sites_enabled_directory}/001-default-ssl.conf
    				ln -sf #{apache_s9s_ccv2_frontend_conf_src_file} #{apache_s9s_ccv2_frontend_conf_target_file}
    				ln -sf #{apache_s9s_ccv2_proxy_conf_src_file} #{apache_s9s_ccv2_proxy_conf_target_file}
    			EOH
    	end
    elsif platform_family?("rhel")
        code <<-EOH

            chkconfig --levels 235 httpd on

            apache_version=$(apachectl -v | grep -i "server version" | cut -d' ' -f3)
            [[ "${apache_version%.*}" == "Apache/2.4"  ]] && use_apache24=1

            if [[ ! -z $use_apache24 ]]; then
                # enable sameorigin header
                if [[ ! -f #{apache_security_conf_file} ]]; then
                    # enable for header
                    cat > #{apache_security_conf_file} << EOF
Header set X-Frame-Options: "sameorigin"
EOF
                fi
                # restart the web server after the controller has been installed
            fi
            
        EOH
    end    
  end
	not_if { FileTest.exists?("#{cc_flag}") }
end

template "cmon.default" do
	path "/etc/default/cmon"
	source "cmon.default.erb"
	owner "root"
	group "root"
	mode "0600"
  # notifies :restart, resources(:service => "cmon")
end

template "cmon.cnf" do
	path "/etc/cmon.cnf"
	source "cmon.cnf.erb"
	owner "root"
	group "root"
	mode "0600"
  variables(
    :cmon_mysql_port => cmon_mysql_port,
    :cmon_mysql_hostname => cmon_mysql_hostname,
    :cmon_mysql_password => cmon_mysql_password,
    :cmon_hostname => cmon_hostname,
    :cmon_rpc_key => cmon_rpc_key,
    :controller_id => controller_id,
    :apache_server_hostname => apache_server_hostname
  )
  # notifies :restart, resources(:service => ["cmon"])
  action :create
  notifies :create, resources(:template => "configure_cmon_db_mysql8.sql.erb"), :immediately
  notifies :run, resources(:execute => "configure-cmon-db"), :immediately
  notifies :restart, 'service[cmon]', :immediately
  if (node['only_cc_v2'] == false)
    ## for ccv1 and ccv2
    notifies :install, 'package[clustercontrol]', :immediately
    notifies :run, 'execute[cc-import-structure-data]', :immediately
    notifies :create, "file[#{cmon_www_bootstrap_file}]", :immediately
    notifies :run, "bash[configure-web-app-bootstrap-file]", :immediately
  end
  
  if (node['only_cc_v2'] and platform?("rhel"))
    ## do not run pre-configure-web-app when its rhel but CC v2 is only the installation UI
  else
    notifies :run, 'bash[pre-configure-web-app]', :immediately
  end
  
  if (node['only_cc_v2'] == false)
    ## for ccv1 and ccv2
    notifies :run, 'execute[cc-insert-api-key-to-dcps-schema]', :immediately
  else
    
  end
end

if (node['only_cc_v2'] == false)
  ## when ccv1 and ccv2 installation
  file "#{cmon_www_bootstrap_file}" do
  	owner "#{apache_user}"
  	group "#{apache_user}"
    mode 0600
    content lazy { ::File.open("#{cmon_www_bootstrap_file}.default").read }
    action :nothing
    # not_if { FileTest.exists?("#{cc_flag}") }
  end

  bash "configure-web-app-bootstrap-file" do
    action :nothing
  	user "root"
      code lazy { <<-EOH
        sed -i "s|^define('DB_PASS'.*|define('DB_PASS', '#{cmon_mysql_password}');|g" #{cmon_www_bootstrap_file}
        sed -i "s|^define('DB_PORT'.*|define('DB_PORT', '#{cmon_mysql_port}');|g" #{cmon_www_bootstrap_file}
        sed -i "s|^define('RPC_TOKEN'.*|define('RPC_TOKEN', '#{cmon_rpc_key}');|g" #{cmon_www_bootstrap_file}
        sed -i "s|^define('CONTAINER'.*|define('CONTAINER', '#{cmon_container}');|g" #{cmon_www_bootstrap_file}

        grep -q "define('CONTAINER'.*" /var/www/html/clustercontrol/bootstrap.php
        [[ $? -eq 1 ]] && echo "define('CONTAINER', 'NA');" >> /var/www/html/clustercontrol/bootstrap.php
        
        chmod o-r #{cmon_www_bootstrap_file}
      EOH
      }
  end
  
end

## generate certificates for https access
template "create_cert.sh.erb" do
	path "/tmp/create_cert.sh"
	source "create_cert.sh.erb"
  variables(
    :cert_file => cert_file,
    :key_file => key_file
  )
	owner "root"
	group "root"
	mode "0600"
	not_if { FileTest.exists?("#{cc_flag}") }
end


execute "run_create_cert.sh" do
	command "bash /tmp/create_cert.sh"
	action :run
	not_if { FileTest.exists?("#{cc_flag}") }
end


if platform_family?("debian")  
  mycmd = "a2enmod rewrite ssl proxy proxy_http proxy_wstunnel headers;"
  
	execute "enable-modules-site" do
		command mycmd
		action :nothing
    # notifies :restart, resources(:service => "#{node['apache']['service_name']}"), :immediately
		not_if { FileTest.exists?("#{cc_flag}") }
	end
elsif platform_family?("rhel")
  bash  "enable-modules-site" do
		action :nothing
  	user "root"
      code lazy { <<-EOH
        if [[ -d /var/lib/php ]]; then
            [[ ! -d /var/lib/php/session ]] && mkdir -p /var/lib/php/session && chmod og=+wxt /var/lib/php/session
        fi
        grep -q "Listen 443" #{apache_conf_file}
        [[ $? -eq 1 ]] && sed -i '1s/^/Listen 443\n/'  #{apache_conf_file} &>/dev/null
        grep -q "ServerName 127.0.0.1"  #{apache_conf_file}
        [[ $? -eq 1 ]] && sed -i '1s/^/ServerName 127.0.0.1\n/'  #{apache_conf_file} &>/dev/null

        if [[ ! -f #{apache_security_conf_file} ]]; then
            cat > #{apache_security_conf_file}  << EOF
Header set X-Frame-Options: "sameorigin"
EOF
        fi
      EOH
      }
  end
end

service "cmon" do
	supports :restart => true, :start => true, :stop => true, :reload => true
  # action [ :enable, :start ]
  action :nothing

  # if (node['only_cc_v2'] == false)
  #   notifies :create, "file[#{cmon_www_bootstrap_file}]", :immediately
  #   notifies :run, "bash[configure-web-app-bootstrap-file]", :immediately
  # end
end

bash "configure-web-app" do
	user "root"
  if (node['only_cc_v2'])
    code lazy { <<-EOH
    	mkdir -p #{wwwroot}/cmon/upload
    	chown -Rf #{apache_user}:#{apache_user} #{wwwroot}/cmon
    	cat #{cmon_os_user_home_dir}/.ssh/id_rsa.pub >> #{cmon_os_user_home_dir}/.ssh/authorized_keys
    	chmod 600 #{node['ssh_user_home']}/.ssh/authorized_keys
      sed -i "s|^[ \t]*USER_REGISTRATION:.*|  USER_REGISTRATION: 1,|g" #{ccv2_webroot_directory}/config.js
      sed -i "s|^[ \t]*ServerName.*|        ServerName #{apache_server_hostname}|g" #{apache_s9s_ccv2_frontend_conf_src_file}
      sed -i "s|https://cc2.severalnines.local:9443.*|https://#{apache_server_hostname}\/|g" #{apache_s9s_ccv2_frontend_conf_src_file}
      sed -i "s|Listen 9443|#Listen 443|g" #{apache_s9s_ccv2_frontend_conf_src_file}
      sed -i "s|9443|443|g" #{apache_s9s_ccv2_frontend_conf_src_file}
    EOH
    }
  else
    ## ccv1 and ccv2
    code lazy { <<-EOH
    	mkdir -p #{wwwroot}/cmon/upload
    	chown -Rf #{apache_user}:#{apache_user} #{wwwroot}/cmon
    	cat #{cmon_os_user_home_dir}/.ssh/id_rsa.pub >> #{cmon_os_user_home_dir}/.ssh/authorized_keys
    	chmod 600 #{node['ssh_user_home']}/.ssh/authorized_keys
      sed -i "s|^[ \t]*USER_REGISTRATION:.*|  USER_REGISTRATION: 1,|g" #{ccv2_webroot_directory}/config.js
      sed -i "s|^[ \t]*ServerName.*|        ServerName #{apache_server_hostname}|g" #{apache_s9s_ccv2_frontend_conf_src_file}
      sed -i "s|https://cc2.severalnines.local:9443.*|https://#{apache_server_hostname}\/|g" #{apache_s9s_ccv2_frontend_conf_src_file}
      chmod -R ugo-w #{ccv1_webroot_directory}/ &>/dev/null
      chmod -R ug+w #{ccv1_webroot_directory}/app/tmp &>/dev/null
      chown -R ${apache_user}.${apache_user} #{ccv1_webroot_directory}/
    EOH
    }
  end

  notifies :create, resources(:template => "configure_cmon_db_mysql8.sql.erb"), :immediately
  notifies :run, resources(:execute => "configure-cmon-db"), :immediately
  if platform_family?("debian")
	  notifies :run, resources(:execute => "enable-modules-site"), :immediately
  elsif platform_family?("rhel")
	  notifies :run, resources(:bash => "enable-modules-site"), :immediately
  end
  
	notifies :restart, resources(:service => mysql_service_name), :immediately
	notifies :run, resources(:execute => "sleep-10"), :immediately
	notifies :restart, resources(:service => "cmon"), :immediately
	notifies :run, resources(:execute => "sleep-10"), :immediately
  # notifies :restart, resources(:service => "#{apache_service_name}"), :delayed
  not_if { FileTest.exists?("#{cc_flag}") }
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

home_path = Dir.home("root")
user_path = "#{home_path}/.s9s/ccrpc.conf"

ruby_block "create_ccrpc_user" do
    block do
      #tricky way to load this Chef::Mixin::ShellOut utilities
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)  
      # node.run_state['mysqld_ver'] = shell_out("sudo S9S_USER_CONFIG=#{user_path} s9s user --create --new-password=#{node['cmon']['rpc_key']} --generate-key --private-key-file=~/.s9s/ccrpc.key --group=admins --controller=https://127.0.0.1:9501 ccrpc").stdout
      shell_out("sudo S9S_USER_CONFIG=#{user_path} s9s user --create --new-password=#{cmon_rpc_key} --generate-key --private-key-file=~/.s9s/ccrpc.key --group=admins --controller=https://127.0.0.1:9501 ccrpc").stdout
      shell_out("sudo S9S_USER_CONFIG=#{user_path} s9s user --set --first-name=RPC --last-name=API").stdout
    end
    action :nothing
    notifies :run, 'execute[sleep-10]', :immediately
end

ruby_block "create_ccsetup_user" do
    block do
      #tricky way to load this Chef::Mixin::ShellOut utilities
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out("sudo unlink /tmp/ccsetup.conf").stdout
      shell_out("sudo S9S_USER_CONFIG=/tmp/ccsetup.conf s9s user --create --new-password=admin --group=admins --email-address='#{ccsetup_email}' --controller='https://127.0.0.1:9501' ccsetup").stdout
    end
    action :nothing
    notifies :run, 'execute[sleep-10]', :immediately
end


# execute "create_ccrpc_user" do
#   command "sudo S9S_USER_CONFIG=#{user_path} s9s user --create --new-password=#{cmon_rpc_key} --generate-key --private-key-file=~/.s9s/ccrpc.key --group=admins --controller=https://127.0.0.1:9501 ccrpc"
#   action :nothing
#   returns 0
# end


# execute "create_ccrpc_set_firstname" do
#   command "sudo S9S_USER_CONFIG=#{user_path} s9s user --set --first-name=RPC --last-name=API"
#   action :run
#   returns 0
#   not_if { FileTest.exists?("#{cc_flag}") }
#   notifies :run, 'execute[create_ccrpc_user]', :immediately
# end

# restart services after installed
service "#{apache_service_name}" do
  # action [ :enable, :restart ]
	action :nothing # [ :enable, :restart ]
  # not_if { FileTest.exists?("#{cc_flag}") }
end

execute "mysql-flag" do
	command "touch #{mysql_flag}"
	action :run
	not_if { FileTest.exists?("#{mysql_flag}") }
end

execute "cc-flag" do
	command "touch #{cc_flag}"
	action :run
  notifies :run, 'ruby_block[create_ccrpc_user]', :immediately
  notifies :run, 'ruby_block[create_ccsetup_user]', :immediately
  notifies :restart, "service[#{apache_service_name}]", :before
	not_if { FileTest.exists?("#{cc_flag}") }
end

