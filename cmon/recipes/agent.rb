#
# Cookbook Name:: cmon
# Recipe:: agent
#
# Copyright 2012, Severalnines AB.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

cmon_config = data_bag_item('s9s_controller', 'config')
node['controller']['mysql_hostname'] = cmon_config['controller_host_ipaddress']
node['cluster_type'] = cmon_config['type']

cmon_package = cmon_config['cmon_package_' + node['kernel']['machine']]
cmon_tarball = cmon_package + ".tar.gz"
Chef::Log.info "Downloading #{cmon_tarball}"
remote_file "#{Chef::Config[:file_cache_path]}/#{cmon_tarball}" do
  source "http://www.severalnines.com/downloads/cmon/" + cmon_tarball
  action :create_if_missing
end

# installs cmon in /usr/local as default
directory node['install_dir_cmon'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

bash "untar-cmon-package" do
  user "root"
  code <<-EOH
    rm -rf #{node['install_dir_cmon']}/cmon
    zcat #{Chef::Config[:file_cache_path]}/#{cmon_tarball} | tar xf - -C #{node['install_dir_cmon']}
    ln -s #{node['install_dir_cmon']}/#{cmon_package} #{node['install_dir_cmon']}/cmon
  EOH
  not_if { File.directory? "#{node['install_dir_cmon']}/#{cmon_package}" }
end

execute "agent-install-privileges" do
  command "#{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -p#{node['mysql']['root_password']} < #{node['sql']['agent_grants']}"
  action :nothing
end

Chef::Log.info "Create agent grants"
template "cmon.agent.grants.sql" do
  path "#{node['sql']['agent_grants']}"
  source "cmon.agent.grants.sql.erb"
  owner "root"
  group "root"
  mode "0644"
#  variables(
#    :user => node['remote']['mysql_user'],
#    :password => node['remote']['mysql_password'],
#    :database => 'cmon'
#  )
  notifies :run, resources(:execute => "agent-install-privileges"), :immediately
end

directory node['misc']['lock_dir'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

service "cmon" do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :nothing
end 

template "cmon.agent.cnf" do
  path "#{node['install_config_path']}/cmon.cnf"
  source "cmon.agent.cnf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "cmon")
end

cookbook_file "/etc/init.d/cmon" do
  backup false
  owner "root"
  group "root"
  mode "0755"
  source "etc/init.d/cmon"
  notifies :restart, resources(:service => "cmon")
end

service "cmon" do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [:enable, :start]
end 
