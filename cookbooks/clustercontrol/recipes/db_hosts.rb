#
# Cookbook Name:: clustercontrol
# Recipe:: default
#
# Copyright 2014, Severalnines AB
#
# All rights reserved - Do Not Redistribute
#
# Configure passwordless SSH to manage hosts
# This recipe should be included on hosts that you want to be managed by ClusterControl

cc_config = data_bag_item('clustercontrol', 'config')

node.override['api_token'] = cc_config['clustercontrol_api_token']
node.override['cmon']['rpc_key'] = cc_config['clustercontrol_api_token']
node.override['cmon']['mysql_password'] = cc_config['cmon_password']
node.override['cmon']['mysql_root_password'] = cc_config['mysql_root_password']
node.override['mysql']['root_password'] = cc_config['mysql_root_password']
node.override['ssh_user'] = cc_config['cmon_ssh_user']
node.override['ssh_user_home'] = cc_config['cmon_user_home']

if "#{node['ssh_user']}" == "root"
	node.set['ssh_user_home'] = "/root"
else
	node.set['ssh_user_home'] = "/home/#{node['ssh_user']}"
end
node.set['cluster_type'] = cc_config['cluster_type']

install_flag = "#{node['ssh_user_home']}/.db_host_configured"

ssh_pub_key = "#{Chef::Config[:file_cache_path]}/cookbooks/clustercontrol/files/default/id_rsa.pub"
cc_pub_key = File.read("#{ssh_pub_key}")
authorized = "#{node['ssh_user_home']}/.ssh/authorized_keys"

if cc_pub_key != nil && cc_pub_key.length > 0
	execute "append-authorized-keys" do
		command "mkdir -p #{node['ssh_user_home']}/.ssh; echo \"#{cc_pub_key}\" >> #{authorized}; touch #{node['ssh_user_home']}/.ssh/.cc_pub_key; chmod 600 #{authorized}; chown #{node['ssh_user']}:#{node['ssh_user']} #{authorized}"
		action :run
		not_if { FileTest.exists?("#{node['ssh_user_home']}/.ssh/.cc_pub_key")}
	end
end

execute "db-host-configured" do
	command "touch #{install_flag}"
	action :run
	not_if { FileTest.exists?("#{install_flag}") }
end
