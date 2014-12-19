#
# Cookbook Name:: clustercontrol
# Recipe:: default
#
# Copyright 2014, Severalnines AB
#
# All rights reserved - Do Not Redistribute
#
# Configure DB hosts
# This recipe should be included on hosts that you want to be managed by ClusterControl

cc_config = data_bag_item('clustercontrol', 'config')
node.set['cmon']['mysql_hostname'] = cc_config['clustercontrol_host']
node.set['cmon']['mysql_password'] = cc_config['cmon_password']
node.set['mysql']['root_password'] = cc_config['mysql_root_password']
node.set['ssh_user'] = cc_config['ssh_user']
if "#{node['ssh_user']}" == "root"
	node.set['user_home'] = "/root"
else
	node.set['user_home'] = "/home/#{node['ssh_user']}"
end
node.set['cluster_type'] = cc_config['cluster_type']

install_flag = "#{node['user_home']}/.db_host_configured"

ssh_pub_key = "#{Chef::Config[:file_cache_path]}/cookbooks/clustercontrol/files/default/id_rsa.pub"
cc_pub_key = File.read("#{ssh_pub_key}")
authorized = "#{node['user_home']}/.ssh/authorized_keys"

if cc_pub_key != nil && cc_pub_key.length > 0
	execute "append-authorized-keys" do
		command "mkdir -p #{node['user_home']}/.ssh; echo \"#{cc_pub_key}\" >> #{authorized}; touch #{node['user_home']}/.ssh/.cc_pub_key; chmod 600 #{authorized}; chown #{node['ssh_user']}:#{node['ssh_user']} #{authorized}"
		action :run
		not_if { FileTest.exists?("#{node['user_home']}/.ssh/.cc_pub_key")}
	end
end

configure_db_host = "#{Chef::Config[:file_cache_path]}/configure_db_host.sql"

execute "configure-db-host" do
	command "#{node['mysql']['bin']} -uroot -p#{node['mysql']['root_password']} < #{configure_db_host}"
	action :nothing
	not_if { FileTest.exists?("#{install_flag}") }
end

if "#{node['cluster_type']}" != "mongodb"
	template "configure_db_host.sql" do
		path "#{configure_db_host}"
		source "configure_db_host.sql.erb"
		owner "root"
		group "root"
		mode "0644"
		notifies :run, resources(:execute => "configure-db-host"), :immediately
	end
end

execute "db-host-configured" do
	command "touch #{install_flag}"
	action :run
	not_if { FileTest.exists?("#{install_flag}") }
end
