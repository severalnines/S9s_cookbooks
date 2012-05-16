#
# Cookbook Name:: cmon
# Recipe:: controller_mysql
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


# Install dependency packages
packages = node['controller']['mysql_packages']
packages.each do |name|
  package name do
    Chef::Log.info "Installing #{name}..."
    action :install
  end
end

# MySQL installed with no root password!
# Let's secure it. Get root password from ['mysql']['root_password']
# todo: maybe erb or tmp file
bash "secure-mysql" do
  user "root"
  code <<-EOH
  #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "UPDATE mysql.user SET Password=PASSWORD('#{node['mysql']['root_password']}') WHERE User='root'"
  #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
  #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "DROP DATABASE test; DELETE FROM mysql.db WHERE DB='test' OR Db='test\\_%;"
  #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "FLUSH PRIVILEGES"
  EOH
  only_if "#{node['mysql']['mysql_bin']} -u root -h127.0.0.1 -e 'show databases;'"
end

# Quick and dirty, stop the mysql server and include our my.cnf to override the default

service "mysql" do
  service_name node['mysql']['service_name']
  if (platform?("ubuntu") && node.platform_version.to_f >= 10.04)
    restart_command "restart mysql"
    stop_command "stop mysql"
    start_command "start mysql"
  end
  supports :stop => true, :start => true, :restart => true, :reload => true
  action :stop
end

template "my.cnf" do
  path "/etc/my.cmon.cnf"
  source "my.cmon.cnf.erb"
  owner "mysql"
  group "mysql"
  mode "0644"
end

execute "cp-my.cmon.cnf" do
  command "cp -f /etc/my.cmon.cnf /etc/mysql/my.cnf"
  action :run
  only_if { FileTest.exists?("/etc/mysql/my.cnf") }
end

execute "cp2-my.cmon.cnf" do
  command "cp -f /etc/my.cmon.cnf /etc/my.cnf"
  action :run
  only_if { FileTest.exists?("/etc/my.cnf") }
end

execute "rm-my.cmon.cnf" do
  command "rm /etc/my.cmon.cnf"
  action :run
  only_if { FileTest.exists?("/etc/my.cmon.cnf") }
end

execute "purge_innodb_logfiles" do
  command "rm #{node['mysql']['data_dir']}/ib_logfile*"
  action :run
  only_if { FileTest.exists?("#{node['mysql']['data_dir']}/ib_logfile0") }
end

execute "set-allow-override" do
  command "sed -i 's/AllowOverride None/AllowOverride All/g' #{node['apache']['default-site']}"
  action :run
end

service ['apache']['service_name'] do
  action :restart
end

service "mysql" do
  supports :stop => true, :start => true, :restart => true, :reload => true
  action [:enable, :start]
end
