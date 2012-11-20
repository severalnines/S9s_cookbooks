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
    options "--force-yes"
  end
end

install_flag = "/root/.s9s_controller_mysql_installed"

# Temp workaround...wait until log files are created and the mysql server
# is up and running otherwise we might have some issues connecting for the
# next steps. Might need to increase sleep time
ruby_block 'wait-until-innodb' do
  block do
    if FileTest.exists?("#{install_flag}") == false
      Chef::Log.info "Temp fix. Sleep a while (#{node['xtra']['sleep']}s) until the mysql server is really up before securing and granting ..."
      sleep node['xtra']['sleep']
    end
  end
end

# MySQL installed with no root password!
# Let's secure it. Get root password from ['cmon_mysql']['root_password']
# todo: maybe erb or tmp file
bash "secure-mysql" do
  user "root"
  code <<-EOH
  #{node['cmon_mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "UPDATE mysql.user SET Password=PASSWORD('#{node['cmon_mysql']['root_password']}') WHERE User='root'"
  #{node['cmon_mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
  #{node['cmon_mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "DROP DATABASE test; DELETE FROM mysql.db WHERE DB='test' OR Db='test\\_%;"
  #{node['cmon_mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "FLUSH PRIVILEGES"
  EOH
  not_if { FileTest.exists?("#{install_flag}") }
end

# Quick and dirty, stop the mysql server and include our my.cnf to override the default
service "mysql-stop" do
  service_name node['mysql']['service_name']
  action :stop
  not_if { FileTest.exists?("#{install_flag}") }
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

execute "purge-innodb-logfiles" do
  command "rm #{node['cmon_mysql']['datadir']}/ib_logfile*"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end

service "mysql" do
  service_name node['mysql']['service_name']
  supports :stop => true, :start => true, :restart => true, :reload => true
  action :start
  subscribes :restart, resources(:template => 'my.cnf')
end

service "reload-mysql-cnf" do
  service_name node['mysql']['service_name']
  supports :stop => true, :start => true, :restart => true, :reload => true
  action :restart
  not_if { FileTest.exists?("#{install_flag}") }
end

execute "s9s-controller-mysql-installed" do
  command "touch #{install_flag}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end
