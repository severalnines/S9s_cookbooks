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

install_flag = "/root/.s9s_galera_installed"
purge_flag = "/root/.s9s_purge_mysql"

group "mysql" do
end

user "mysql" do
  gid "mysql"
  comment "MySQL server"
  system true
  shell "/bin/false"
end

galera_config = data_bag_item('s9s_galera', 'config')
mysql_tarball = galera_config['mysql_wsrep_tarball_' + node['kernel']['machine']]
# strip .tar.gz
mysql_package = mysql_tarball[0..-8]

mysql_wsrep_source = galera_config['mysql_wsrep_source']
galera_source = galera_config['galera_source']

Chef::Log.info "Downloading #{mysql_tarball}"
remote_file "#{Chef::Config[:file_cache_path]}/#{mysql_tarball}" do
  source "#{mysql_wsrep_source}/" + mysql_tarball
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
  source "#{galera_source}/" + galera_package
  action :create_if_missing
end

bash "expand-mysql-package" do
  user "root"
  code <<-EOH
    rm -rf #{node['galera']['install_dir']}/mysql
    zcat #{Chef::Config[:file_cache_path]}/#{mysql_tarball} | tar xf - -C #{node['galera']['install_dir']}
    ln -sf #{node['galera']['install_dir']}/#{mysql_package} #{node['galera']['install_dir']}/mysql
  EOH
  not_if { File.directory?("#{node['galera']['install_dir']}/#{mysql_package}") }
end

case node['platform']
  when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'
    bash "purge-mysql-galera" do
      user "root"
      code <<-EOH
        killall -9 mysqld_safe mysqld &> /dev/null
        yum remove mysql mysql-libs mysql-devel mysql-server mysql-bench
        rm -rf #{node['mysql']['datadir']}/*
        rm -rf /etc/my.cnf /etc/mysql
        rm -f /root/#{install_flag}
      EOH
      only_if { File.exists?("#{purge_flag}") || !FileTest.exists?("#{install_flag}") }
    end
  else
    bash "purge-mysql-galera" do
      user "root"
      code <<-EOH
        killall -9 mysqld_safe mysqld &> /dev/null
        apt-get -y remove --purge mysql-server mysql-client mysql-common
        apt-get -y autoremove
        apt-get -y autoclean
        rm -rf #{node['mysql']['datadir']}/*
        rm -rf /etc/my.cnf /etc/mysql
        rm -f /root/#{install_flag}
      EOH
      only_if { File.exists?("#{purge_flag}") || !FileTest.exists?("#{install_flag}") }
    end
end

case node['platform']
when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'
  bash "install-galera" do
    user "root"
    code <<-EOH
      yum -y localinstall #{node['xtra']['packages']}
      yum -y localinstall #{Chef::Config[:file_cache_path]}/#{galera_package}
    EOH
    not_if { FileTest.exists?("#{node['wsrep']['provider']}") }
  end
else
  bash "install-galera" do
    user "root"
    code <<-EOH
      apt-get -y --force-yes install #{node['xtra']['packages']}
      dpkg -i #{Chef::Config[:file_cache_path]}/#{galera_package}
      apt-get -f install
    EOH
    not_if { FileTest.exists?("#{node['wsrep']['provider']}") }
  end
end

directory node['mysql']['datadir'] do
  owner "mysql"
  group "mysql"
  mode "0755"
  action :create
  recursive true
end

directory node['mysql']['rundir'] do
  owner "mysql"
  group "mysql"
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
  action :nothing
end

execute "cp-init.d-mysql.server" do
  command "cp #{node['mysql']['basedir']}/support-files/mysql.server /etc/init.d/#{node['mysql']['servicename']}"
  not_if { FileTest.exists?("#{install_flag}") }
end

bash "set-paths.mysql.server" do
  user "root"
  code <<-EOH
  sed -i 's#^basedir.*=#basedir=#{node['mysql']['basedir']}#' /etc/init.d/#{node['mysql']['servicename']}
  sed -i 's#^datadir.*=#datadir=#{node['mysql']['datadir']}#' /etc/init.d/#{node['mysql']['servicename']}
  EOH
  not_if { FileTest.exists?("#{install_flag}") }
end

template "my.cnf" do
  path "/etc/my.cnf"
  source "my.cnf.erb"
  owner "mysql"
  group "mysql"
  mode "0644"
end

my_ip = node['ipaddress']
init_host = galera_config['init_node']
sync_host = init_host

Chef::Log.info "My host = #{my_ip}"
hosts = galera_config['galera_nodes']
if File.exists?("#{install_flag}") && hosts != nil && hosts.length > 0
  i = 0
  begin
    sync_host = hosts[rand(hosts.count)]
    i += 1
    if (i > hosts.count)
      # no host found, use init node/host
      sync_host = init_host
      break
    end
  end while my_ip == sync_host
end

bash "init-cluster" do
  user "root"
  code <<-EOH
  sed -i 's#^wsrep_urls.*=.*#wsrep_urls=gcomm://#' /etc/my.cnf
  EOH
  only_if { my_ip == init_host && !FileTest.exists?("#{install_flag}") }
end

service "start-init-node" do
  service_name node['mysql']['servicename']
  supports :restart => true, :start => true, :stop => true
  action [:enable, :start]
  only_if { my_ip == init_host && !FileTest.exists?("#{install_flag}") }
end

bash "set-wsrep-grants" do
  user "root"
  code <<-EOH
    #{node['mysql']['mysqlbin']} -uroot -h127.0.0.1 -e "SET wsrep_on=0; DELETE FROM mysql.user WHERE user=''; GRANT ALL ON *.* TO '#{node['wsrep']['user']}'@'%' IDENTIFIED BY '#{node['wsrep']['password']}'"
    #{node['mysql']['mysqlbin']} -uroot -h127.0.0.1 -e "SET wsrep_on=0; GRANT ALL ON *.* TO '#{node['wsrep']['user']}'@'127.0.0.1' IDENTIFIED BY '#{node['wsrep']['password']}'"
  EOH
  only_if { my_ip == init_host && (galera_config['sst_method'] == 'mysqldump') && !FileTest.exists?("#{install_flag}") }
end

bash "secure-mysql" do
  user "root"
  code <<-EOH
    #{node['mysql']['mysqlbin']} -uroot -h127.0.0.1 -e "SET wsrep_on=0; UPDATE mysql.user SET Password=PASSWORD('#{node['mysql']['root_password']}') WHERE User='root'; DELETE FROM mysql.user WHERE User=''; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
    #{node['mysql']['mysqlbin']} -uroot -h127.0.0.1 -e "SET wsrep_on=0; DROP DATABASE test; DELETE FROM mysql.db WHERE DB='test' OR Db='test\\_%;"
    #{node['mysql']['mysqlbin']} -uroot -h127.0.0.1 -e "SET wsrep_on=0; FLUSH PRIVILEGES"
  EOH
  only_if { my_ip == init_host && (galera_config['secure'] == 'yes') && !FileTest.exists?("#{install_flag}") }
end

if my_ip != init_host && !File.exists?("#{install_flag}")
Chef::Log.info "Joiner node sleeping 30 seconds to make sure init/sync node is up..."
sleep(30)
Chef::Log.info "Joiner node attaching to cluster with URL = gcomm://#{sync_host}:#{node['wsrep']['port']}"
end

hosts = galera_config['galera_nodes']
wsrep_urls=''
if !File.exists?("#{install_flag}") && hosts != nil && hosts.length > 0
  hosts.each do |h|
    wsrep_urls += "gcomm://#{h}:#{node['wsrep']['port']},"
  end
  wsrep_urls = wsrep_urls[0..-2]
end

bash "set-wsrep_urls" do
  user "root"
  code <<-EOH
  sed -i 's#^wsrep_urls.*=.*#wsrep_urls=#{wsrep_urls}#' /etc/my.cnf
  EOH
  only_if { (galera_config['update_wsrep_urls'] == 'yes') || !FileTest.exists?("#{install_flag}") }
end

service "join-cluster" do
  service_name node['mysql']['servicename']
  supports :restart => true, :start => true, :stop => true
  action [:enable, :start]
  only_if { my_ip != init_host && !FileTest.exists?("#{install_flag}") }
end

execute "s9s-galera-installed" do
  command "touch #{install_flag}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end

