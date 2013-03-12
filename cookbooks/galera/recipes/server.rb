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

# Vagrant host only fix
Ohai::Config[:plugin_path] << node['vagrant-ohai']['plugin_path']
Chef::Log.info("vagrant ohai plugins will be at: #{node['vagrant-ohai']['plugin_path']}")

rd = remote_directory node['vagrant-ohai']['plugin_path'] do
  source 'plugins'
  owner 'root'
  group 'root'
  mode 0755
  recursive true
  action :nothing
end

rd.run_action(:create)

# only reload ohai if new plugins were dropped off OR
# node['vagrant-ohai']['plugin_path'] does not exists in client.rb
if rd.updated? || 
  !(::IO.read(Chef::Config[:config_file]) =~ /Ohai::Config\[:plugin_path\]\s*<<\s*["']#{node['vagrant-ohai']['plugin_path']}["']/)

  ohai 'custom_plugins' do
    action :nothing
  end.run_action(:reload)

end

# Vagrant host only fix end

install_flag = "/root/.s9s_galera_installed"

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

bash "install-mysql-package" do
  user "root"
  code <<-EOH
    zcat #{Chef::Config[:file_cache_path]}/#{mysql_tarball} | tar xf - -C #{node['mysql']['install_dir']}
    ln -sf #{node['mysql']['install_dir']}/#{mysql_package} #{node['mysql']['base_dir']}
  EOH
  not_if { File.directory?("#{node['mysql']['install_dir']}/#{mysql_package}") }
end

case node['platform']
  when 'centos', 'redhat', 'fedora', 'suse', 'scientific', 'amazon'
    bash "purge-mysql-galera" do
      user "root"
      code <<-EOH
        killall -9 mysqld_safe mysqld &> /dev/null
        yum remove mysql mysql-libs mysql-devel mysql-server mysql-bench
        cd #{node['mysql']['data_dir']}
        [ $? -eq 0 ] && rm -rf #{node['mysql']['data_dir']}/*
        rm -rf /etc/my.cnf /etc/mysql
        rm -f /root/#{install_flag}
      EOH
      only_if { !FileTest.exists?("#{install_flag}") }
    end
  else
    bash "purge-mysql-galera" do
      user "root"
      code <<-EOH
        killall -9 mysqld_safe mysqld &> /dev/null
        apt-get -y remove --purge mysql-server mysql-client mysql-common
        apt-get -y autoremove
        apt-get -y autoclean
        cd #{node['mysql']['data_dir']}
        [ $? -eq 0 ] && rm -rf #{node['mysql']['data_dir']}/*
        rm -rf /etc/my.cnf /etc/mysql
        rm -f /root/#{install_flag}
      EOH
      only_if { !FileTest.exists?("#{install_flag}") }
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

directory node['mysql']['data_dir'] do
  owner "mysql"
  group "mysql"
  mode "0755"
  action :create
  recursive true
end

directory node['mysql']['run_dir'] do
  owner "mysql"
  group "mysql"
  mode "0755"
  action :create
  recursive true
end

# install db to the data directory
execute "setup-mysql-datadir" do
  command "#{node['mysql']['base_dir']}/scripts/mysql_install_db --force --user=mysql --basedir=#{node['mysql']['base_dir']} --datadir=#{node['mysql']['data_dir']}"
  not_if { FileTest.exists?("#{node['mysql']['data_dir']}/mysql/user.frm") }
end


execute "setup-init.d-mysql-service" do
  command "cp #{node['mysql']['base_dir']}/support-files/mysql.server /etc/init.d/#{node['mysql']['servicename']}"
  not_if { FileTest.exists?("#{install_flag}") }
end

template "my.cnf" do
  path "#{node['mysql']['conf_dir']}/my.cnf"
  source "my.cnf.erb"
  owner "mysql"
  group "mysql"
  mode "0644"
#  notifies :restart, "service[mysql]", :delayed
end

my_ip = node['ipaddress']
init_host = galera_config['init_node']
sync_host = init_host

hosts = galera_config['galera_nodes']
Chef::Log.info "init_host = #{init_host}, my_ip = #{my_ip}, hosts = #{hosts}"
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

wsrep_cluster_address = 'gcomm://'
if !File.exists?("#{install_flag}") && hosts != nil && hosts.length > 0
  hosts.each do |h|
    wsrep_cluster_address += "#{h}:#{node['wsrep']['port']},"
  end
  wsrep_cluster_address = wsrep_cluster_address[0..-2]
end

Chef::Log.info "wsrep_cluster_address = #{wsrep_cluster_address}"
bash "set-wsrep-cluster-address" do
  user "root"
  code <<-EOH
  sed -i 's#.*wsrep_cluster_address.*=.*#wsrep_cluster_address=#{wsrep_cluster_address}#' #{node['mysql']['conf_dir']}/my.cnf
  EOH
  only_if { (galera_config['update_wsrep_urls'] == 'yes') || !FileTest.exists?("#{install_flag}") }
end

service "init-cluster" do
  service_name node['mysql']['servicename']
  supports :start => true
  start_command "service #{node['mysql']['servicename']} start --wsrep-cluster-address=gcomm://"
  action [:enable, :start]
  only_if { my_ip == init_host && !FileTest.exists?("#{install_flag}") }
end

if my_ip != init_host && !File.exists?("#{install_flag}")
Chef::Log.info "Joiner node sleeping 30 seconds to make sure donor node is up..."
sleep(node['xtra']['sleep'])
Chef::Log.info "Joiner node cluster address = gcomm://#{sync_host}:#{node['wsrep']['port']}"
end

service "join-cluster" do
  service_name node['mysql']['servicename']
  supports :restart => true, :start => true, :stop => true
  action [:enable, :start]
  only_if { my_ip != init_host && !FileTest.exists?("#{install_flag}") }
end

bash "wait-until-synced" do
  user "root"
  code <<-EOH
    state=0
    cnt=0
    until [[ "$state" == "4" || "$cnt" > 5 ]]
    do
      state=$(#{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "SET wsrep_on=0; SHOW GLOBAL STATUS LIKE 'wsrep_local_state'")
      state=$(echo "$state"  | tr '\n' ' ' | awk '{print $4}')
      cnt=$(($cnt + 1))
      sleep 1
    done
  EOH
  only_if { my_ip == init_host && !FileTest.exists?("#{install_flag}") }
end

bash "set-wsrep-grants-mysqldump" do
  user "root"
  code <<-EOH
    #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "GRANT ALL ON *.* TO '#{node['wsrep']['user']}'@'%' IDENTIFIED BY '#{node['wsrep']['password']}'"
    #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "SET wsrep_on=0; GRANT ALL ON *.* TO '#{node['wsrep']['user']}'@'127.0.0.1' IDENTIFIED BY '#{node['wsrep']['password']}'"
  EOH
  only_if { my_ip == init_host && (galera_config['sst_method'] == 'mysqldump') && !FileTest.exists?("#{install_flag}") }
end

bash "secure-mysql" do
  user "root"
  code <<-EOH
    #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "DROP DATABASE IF EXISTS test; DELETE FROM mysql.db WHERE DB='test' OR DB='test\\_%'"
    #{node['mysql']['mysql_bin']} -uroot -h127.0.0.1 -e "UPDATE mysql.user SET Password=PASSWORD('#{node['mysql']['root_password']}') WHERE User='root'; DELETE FROM mysql.user WHERE User=''; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); FLUSH PRIVILEGES;"
  EOH
  only_if { my_ip == init_host && (galera_config['secure'] == 'yes') && !FileTest.exists?("#{install_flag}") }
end

service "mysql" do
  supports :restart => true, :start => true, :stop => true
  service_name node['mysql']['servicename']
  action :nothing
  only_if { FileTest.exists?("#{install_flag}") }
end

execute "s9s-galera-installed" do
  command "touch #{install_flag}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end
