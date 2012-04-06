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

# downlod cmon package
cmon_package="cmon-1.1.25-64bit-glibc23-mc70.tar.gz"
Chef::Log.info "Downloading #{cmon_package}"
remote_file "#{Chef::Config[:file_cache_path]}/cmon.tar.gz" do
  source "http://www.severalnines.com/downloads/cmon/" + cmon_package
  action :create_if_missing
end

# install cmon in /usr/local/cmon as default
directory node['cmon']['install_dir_cmon'] do
  owner "root"
  mode "0755"
  action :create
end

directory node['cmon']['misc']['lock_dir'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

bash "unpack_cmon_package" do
  user "root"
  code <<-EOH
  	rm -rf #{node['cmon']['install_dir_cmon']}/cmon
		cmon_name=`echo "#{cmon_package}" | awk -F ".tar"  '{print $1}'`
		echo $cmon_name > /tmp/alex
		zcat #{Chef::Config[:file_cache_path]}/cmon.tar.gz | tar xf - -C #{node['cmon']['install_dir_cmon']}
		ln -s #{node['cmon']['install_dir_cmon']}/$cmon_name #{node['cmon']['install_dir_cmon']}/cmon
  EOH
end

service "cmon" do
	supports :restart => true, :start => true, :stop => true, :reload => true
  action :nothing
end 

template "cmon.agent.cnf" do
	path "#{node['cmon']['install_configpath']}/cmon.cnf"
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

#execute "start-cmon" do
#  command %Q{/etc/init.d/cmon start}
#  creates {node['cmon']['misc']['pid_file']}
#end

