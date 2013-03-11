#
# Cookbook Name:: cmon
# Recipe:: controller
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

install_flag = "/root/.s9s_controller_installed"

cmon_config = data_bag_item('s9s_controller', 'config')
node.set['controller']['mysql_hostname'] = cmon_config['controller_host_ipaddress']
node.set['mode']['controller'] = cmon_config['mode']
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

execute "gen-ssh-key" do
  command "ssh-keygen -t rsa -N \"\" -f #{node['controller']['ssh_key']}"
  action :run
  not_if { FileTest.exists? "#{node['controller']['ssh_key']}" }
end

# install cmon in /usr/local/cmon as default
directory node['install_dir_cmon'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

bash "extract-cmon-package" do
  user "root"
  code <<-EOH
    killall -9 cmon &> /dev/null
    rm -rf #{node['install_dir_cmon']}/cmon
    gz=`file #{Chef::Config[:file_cache_path]}/#{cmon_tarball} | grep -i gzip`
    if [ -z "$gz" ]
    then
      cat #{Chef::Config[:file_cache_path]}/#{cmon_tarball} | tar xf - -C #{node['install_dir_cmon']}
    else
      zcat #{Chef::Config[:file_cache_path]}/#{cmon_tarball} | tar xf - -C #{node['install_dir_cmon']}
    fi
    ln -sf #{node['install_dir_cmon']}/#{cmon_package} #{node['install_dir_cmon']}/cmon
  EOH
  not_if { File.directory? "#{node['install_dir_cmon']}/#{cmon_package}" }
end

execute "controller-create-db-schema" do
  command "#{node['cmon_mysql']['mysql_bin']} -uroot -p#{node['cmon_mysql']['root_password']} < #{node['sql']['cmon_schema']}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end

execute "controller-import-tables" do
  command "#{node['cmon_mysql']['mysql_bin']} -uroot -p#{node['cmon_mysql']['root_password']} < #{node['sql']['cmon_data']}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end

execute "controller-install-privileges" do
  command "#{node['cmon_mysql']['mysql_bin']} -uroot -p#{node['cmon_mysql']['root_password']} < #{node['sql']['controller_grants']}"
  action :nothing
  not_if { FileTest.exists?("#{install_flag}") }
end

template "cmon.controller.grants.sql" do
  path "#{node['sql']['controller_grants']}"
  source "cmon.controller.grants.sql.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :run, resources(:execute => "controller-install-privileges"), :immediately
end


agents = data_bag_item('s9s_controller', 'config')
hosts = agents['agent_hosts']
host_list = ""
hosts.each do |h|
 host_list << h + " "
end

bash "create-agent-grants" do
  user "root"
  code <<-EOH
    for h in #{host_list}
    do
      echo "GRANT SUPER ON *.* TO 'cmon'@'$h' IDENTIFIED BY '#{node['cmon_password']}';" >> #{node['sql']['controller_agent_grants']}
      echo "GRANT INSERT,UPDATE,DELETE,SELECT ON cmon.* TO 'cmon'@'$h' IDENTIFIED BY '#{node['cmon_password']}';" >> #{node['sql']['controller_agent_grants']}
      ssh-keyscan -t rsa $h >> /root/.ssh/known_hosts
    done
  EOH
  not_if { FileTest.exists?(node['sql']['controller_agent_grants']) }
end

execute "controller-grant-agents" do
  command "#{node['cmon_mysql']['mysql_bin']} -uroot -p#{node['cmon_mysql']['root_password']} < #{node['sql']['controller_agent_grants']}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end

directory node['misc']['core_dir'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

remote_directory "#{node['misc']['core_dir']}/mysql" do
  source "s9s/#{node['cluster_type']}/mysql"
  files_backup 0
  files_owner "root"
  files_group "root"
  files_mode "0755"
  not_if { File.directory?("#{node['misc']['core_dir']}/mysql") }
end

execute "install-core-scripts" do
  command "cp #{node['install_dir_cmon']}/cmon/bin/cmon_* /usr/bin/"
  action :run
  not_if { FileTest.exists?("/usr/bin/cmon_rrd_all") }
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

template "cmon_rrd.cnf" do
  path "#{node['install_config_path']}/cmon_rrd.cnf"
  source "cmon_rrd.cnf.erb"
  owner "root"
  group "root"
  mode "0644"
end

template "cmon.controller.cnf" do
  path "#{node['install_config_path']}/cmon.cnf"
  source "cmon.controller.cnf.erb"
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
  supports :restart => true, :start => true, :stop => true
  action [:enable, :start]
end

execute "s9s-controller-installed" do
  command "touch #{install_flag}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end
