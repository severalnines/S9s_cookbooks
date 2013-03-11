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

install_flag = "/root/.s9s_agent_installed"

cmon_config = data_bag_item('s9s_controller', 'config')
node.set['controller']['mysql_hostname'] = cmon_config['controller_host_ipaddress']
node.set['cluster_type'] = cmon_config['type']

cmon_tarball = cmon_config['cmon_tarball_' + node['kernel']['machine']]
# strip .tar.gz
cmon_package = cmon_tarball[0..-8]
cmon_source = cmon_config['cmon_source']

Chef::Log.info "Downloading #{cmon_tarball}"
remote_file "#{Chef::Config[:file_cache_path]}/#{cmon_tarball}" do
  source "#{cmon_source}/#{cmon_tarball}"
  action :create_if_missing
end

cc_pub_key = cmon_config['cc_pub_key']
if cc_pub_key != nil && cc_pub_key.length > 0
  execute "append-authorized-keys" do
    command "mkdir -p /root/.ssh; echo #{cc_pub_key} >> /root/.ssh/authorized_keys; touch /root/.ssh/.cc_pub_key; chmod 600 /root/.ssh/authorized_keys"
    action :run
    not_if { FileTest.exists?("/root/.ssh/.cc_pub_key") }
  end
end

directory node['install_dir_cmon'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

bash "extract-cmon-package" do
  user "root"
  code <<-EOH
    rm -rf #{node['install_dir_cmon']}/cmon
    gz=`file #{Chef::Config[:file_cache_path]}/#{cmon_tarball} | grep -i gzip`
    if [ -z "$gz" ]
    then
      cat #{Chef::Config[:file_cache_path]}/#{cmon_tarball} | tar xf - -C #{node['install_dir_cmon']}    
    else
      zcat #{Chef::Config[:file_cache_path]}/#{cmon_tarball} | tar xf - -C #{node['install_dir_cmon']}
    fi
    ln -s #{node['install_dir_cmon']}/#{cmon_package} #{node['install_dir_cmon']}/cmon
  EOH
  not_if { File.directory? "#{node['install_dir_cmon']}/#{cmon_package}" }
end

execute "agent-install-privileges" do
  command "#{node['cmon_mysql']['mysql_bin']} -uroot -h127.0.0.1 -p#{node['cmon_mysql']['root_password']} < #{node['sql']['agent_grants']}"
  action :nothing
  not_if { FileTest.exists?("#{install_flag}") }
end

grants_file = 'cmon.agent.grants.sql.erb'
if node['cluster_type'] == 'galera'
  grants_file = 'cmon.agent.grants.sql.galera.erb'
end

template "cmon.agent.grants.sql" do
  path "#{node['sql']['agent_grants']}"
  source "#{grants_file}"
  owner "root"
  group "root"
  mode "0644"
  notifies :run, resources(:execute => "agent-install-privileges"), :immediately
end

directory node['misc']['lock_dir'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

service "cmon" do
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
  supports :restart => true, :start => true, :stop => true, :status => true
  action [:enable, :start]
end

execute "s9s-agent-installed" do
  command "touch #{install_flag}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end
