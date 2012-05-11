#
# Cookbook Name:: cmon
# Recipe:: webapp
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

cmon_config = data_bag_item('controller', 'config')

cmon_package=cmon_config['cmon_package_' + node['kernel']['machine']]
Chef::Log.info "Downloading #{cmon_package}.tar.gz to #{Chef::Config[:file_cache_path]}/cmon.tar.gz"
remote_file "#{Chef::Config[:file_cache_path]}/cmon.tar.gz" do
  source "http://www.severalnines.com/downloads/cmon/" + cmon_package + ".tar.gz"
  action :create_if_missing
end

# installs cmon in /usr/local as default
directory node['cmon']['install_dir_cmon'] do
  owner "root"
  mode "0755"
  action :create
  recursive true
end

bash "untar-cmon-package" do
  user "root"
  code <<-EOH
    rm -rf #{node['cmon']['install_dir_cmon']}/cmon
    zcat #{Chef::Config[:file_cache_path]}/cmon.tar.gz | tar xf - -C #{node['cmon']['install_dir_cmon']}
    ln -s #{node['cmon']['install_dir_cmon']}/#{cmon_package} #{node['cmon']['install_dir_cmon']}/cmon
  EOH
  not_if { File.directory? "#{node['cmon']['install_dir_cmon']}/cmon" }
end

bash "install-web-app" do
  user "root"
  code <<-EOH
    cp #{node['cmon']['install_dir_cmon']}/cmon/etc/cron.d/cmon /etc/cron.d/cmon
    mkdir -p #{node['cmon']['misc']['wwwwroot']}/cmon
    mkdir -p /var/lib/cmon
    mkdir -p #{node['cmon']['misc']['wwwwroot']}/cmon/graphs
    mkdir -p #{node['cmon']['misc']['wwwwroot']}/cmon/upload/schema
    cp -rf #{node['cmon']['install_dir_cmon']}/cmon/www/*  #{node['cmon']['misc']['wwwwroot']}/
    chown -R #{node['cmon']['misc']['web_user']}:#{node['cmon']['misc']['web_user']} #{node['cmon']['misc']['wwwwroot']}/cmon
  EOH
end
