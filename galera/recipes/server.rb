#
# Cookbook Name:: galera
# Recipe:: galera_server
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

# TODO: Calling SET GLOBAL wsrep_cluster_address='gcomm://' only works once...
# Doing it a second time a mysql client is not able to connect and the mysql node is no longer a primary
# We need to restart the mysql server and then set address again


# TODO: Firewall, selinux and apparmor
# iptables --insert RH-Firewall-1-INPUT 1 --proto tcp --source <my IP>/24 --destination <my IP>/32 --dport 3306 -j ACCEPT
# iptables --insert RH-Firewall-1-INPUT 1 --proto tcp --source <my IP>/24 --destination <my IP>/32 --dport 4567 -j ACCEPT
#'setenforce 0' as root.
# set 'SELINUX=permissive' in  /etc/selinux/config
#cd /etc/apparmor.d/disable/
# sudo ln -s /etc/apparmor.d/usr.sbin.mysqld
#sudo service apparmor restart


group "mysql" do
end

user "mysql" do
  gid "mysql"
  comment "MySQL server"
  system true
  shell "/bin/false"
end

galera_config = data_bag_item('s9s_galera', 'config')

mysql_package = galera_config['mysql_wsrep_package_' + node['kernel']['machine']]
mysql_tarball = mysql_package + ".tar.gz"
Chef::Log.info "Downloading #{mysql_tarball}"
remote_file "#{Chef::Config[:file_cache_path]}/#{mysql_tarball}" do
  source "https://launchpad.net/codership-mysql/5.5/5.5.23-23.5/+download/" + mysql_tarball
  action :create_if_missing
end

case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'
  galera_package = galera_config['galera_package_' + node['kernel']['machine']]['rpm']
else
  galera_package = galera_config['galera_package_' + node['kernel']['machine']]['deb']
end

Chef::Log.info "Downloading #{galera_package}"
remote_file "#{Chef::Config[:file_cache_path]}/#{galera_package}" do
  source "https://launchpad.net/galera/2.x/23.2.0/+download/" + galera_package
  action :create_if_missing
end

bash "untar-mysql-package" do
  user "root"
  code <<-EOH
    rm -rf #{node['galera']['install_dir']}/mysql_galera
    zcat #{Chef::Config[:file_cache_path]}/#{mysql_tarball} | tar xf - -C #{node['galera']['install_dir']}
    ln -s #{node['galera']['install_dir']}/#{mysql_package} #{node['galera']['install_dir']}/mysql_galera
  EOH
  not_if { File.directory?("#{node['galera']['install_dir']}/#{galera_package}") }
end

case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'
  bash "purge-mysql-n-install-galera" do
    user "root"
    code <<-EOH
      rpm -e --nodeps --allmatches mysql mysql-devel mysql-server mysql-bench
      rm -rf /var/lib/mysql/*
      rm -rf /etc/my.cnf /etc/mysql
      rpm -Uhv #{node['xtra']['packages']}
      rpm -Uhv #{Chef::Config[:file_cache_path]}/#{galera_package}
    EOH
    not_if { FileTest.exists?("#{node['wsrep']['provider']}") }
  end
else
  bash "purge-mysql-n-install-galera" do
    user "root"
    code <<-EOH
      apt-get -y remove --purge mysql-server
      apt-get -y remove --purge mysql-client
      apt-get -y remove --purge mysql-common
      apt-get -y autoremove
      apt-get -y autoclean
      rm -rf /var/lib/mysql/*
      rm -rf /etc/my.cnf /etc/mysql
      apt-get -y install #{node['xtra']['packages']}
      dpkg -i #{Chef::Config[:file_cache_path]}/#{galera_package}
    EOH
    not_if { FileTest.exists?("#{node['wsrep']['provider']}") }
  end
end

directory node['mysql']['datadir'] do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

# install db to the data directory
execute "setup-mysql-datadir" do
  command "#{node['mysql']['basedir']}/scripts/mysql_install_db --force --user=mysql --basedir=#{node['mysql']['basedir']} --datadir=#{node['mysql']['datadir']}"
  not_if { FileTest.exists?("#{node['mysql']['datadir']}/mysql/user.frm") }
end

service "mysql" do
  service_name node['mysql']['servicename']
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :nothing
#  subscribes :restart, resources(:tempate => 'my.cnf')
end 

template "mysqld" do
  path "/etc/init.d/mysqld"
  source "mysqld.erb"
  owner "mysql"
  group "mysql"
  mode "0755"
end

template "my.cnf" do
  path "/etc/my.cnf"
  source "my.cnf.erb"
  owner "mysql"
  group "mysql"
  mode "0644"
end

service "mysql" do
  service_name node['mysql']['servicename']
  action [:enable, :start]
end

# Temp workaround...wait until log files are created and the mysql server
# is up and running otherwise we might have some issues connecting for the
# next steps. Might need to increase sleep time
ruby_block 'wait-until-innodb' do
  block do
    if FileTest.exists?("#{node['mysql']['datadir']}/galera.cache") == false
      Chef::Log.info "Sleep a while (20s) until the mysql server is up..."
      sleep 20
    end
  end
end

bash "set-wsrep-grants" do
  user "root"
  code <<-EOH
    #{node['mysql']['mysqlbin']} -uroot -e "SET wsrep_on=OFF; DELETE FROM mysql.user WHERE user='';"
    #{node['mysql']['mysqlbin']} -uroot -e "SET wsrep_on=OFF; GRANT ALL ON *.* TO '#{node['wsrep']['user']}'@'%' IDENTIFIED BY '#{node['wsrep']['password']}'"
  EOH
  only_if "#{node['mysql']['mysqlbin']} -uroot -e 'show databases'"
end

bash "secure-mysql" do
  user "root"
  code <<-EOH
    #{node['mysql']['mysqlbin']} -uroot -e "SET wsrep_on=OFF; UPDATE mysql.user SET Password=PASSWORD('#{node['mysql']['root_password']}') WHERE User='root'"
    #{node['mysql']['mysqlbin']} -uroot -e "SET wsrep_on=OFF; DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    #{node['mysql']['mysqlbin']} -uroot -e "SET wsrep_on=OFF; DROP DATABASE test; DELETE FROM mysql.db WHERE DB='test' OR Db='test\\_%;"
    #{node['mysql']['mysqlbin']} -uroot -e "SET wsrep_on=OFF; FLUSH PRIVILEGES"
  EOH
  only_if "#{node['mysql']['mysqlbin']} -uroot -e 'show databases'"
end

# not use atm
primary = galera_config['primary']

hosts = galera_config['galera_hosts']
my_ip = node['ipaddress']

sync_host = hosts[rand(hosts.count)]
i = 0
single_node = hosts.count == 1 ? true : false
if single_node == false
  while my_ip == sync_host
    sync_host = hosts[rand(hosts.count)]
    i += 1
    if (i > hosts.count)
      # not in host list
      single_node = true
      break
    end
  end
end

# TODO: Cluster restart
# The first node of a cluster has nowhere to connect to, therefore it has to start
# with an empty cluster addres
# We need to have the primary node use the gcomm:// address

if single_node
  execute "set-wsrep-address" do
    command "#{node['mysql']['mysqlbin']} -uroot -p#{node['mysql']['root_password']} -h127.0.0.1 -e \"SET GLOBAL wsrep_cluster_address='gcomm://'\""
    action :run
    #subscribes :run, resources(:template => 'my.cnf')
  end
else
  Chef::Log.info "Synching with host: " + sync_host
  execute "set-wsrep-address" do
    command "#{node['mysql']['mysqlbin']} -uroot -p#{node['mysql']['root_password']} -h127.0.0.1 -e \"SET GLOBAL wsrep_cluster_address='gcomm://#{sync_host}:#{node['wsrep']['port']}'\""
    action :run
    #subscribes :run, resources(:template => 'my.cnf')
  end
end
