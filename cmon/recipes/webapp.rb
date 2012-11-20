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

cmon_config = data_bag_item('s9s_controller', 'config')
cmon_tarball = cmon_config['cmon_tarball_' + node['kernel']['machine']]
# strip .tar.gz
cmon_package = cmon_tarball[0..-8]
cmon_source = cmon_config['cmon_source']

remote_file "#{Chef::Config[:file_cache_path]}/#{cmon_tarball}" do
  source "#{cmon_source}/#{cmon_tarball}"
  action :create_if_missing
end

# installs cmon in /usr/local as default
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

bash "install-web-app" do
  user "root"
  code <<-EOH
    cp #{node['install_dir_cmon']}/cmon/etc/cron.d/cmon /etc/cron.d/cmon
    mkdir -p #{node['misc']['wwwroot']}/cmon
    mkdir -p /var/lib/cmon
    mkdir -p #{node['misc']['wwwroot']}/cmon/graphs
    mkdir -p #{node['misc']['wwwroot']}/cmon/upload/schema
    cp -rf #{node['install_dir_cmon']}/cmon/www/*  #{node['misc']['wwwroot']}/
    chown -R #{node['misc']['web_user']}:#{node['misc']['web_user']} #{node['misc']['wwwroot']}/cmon
  EOH
  not_if { File.directory?("#{node['misc']['wwwroot']}/cmon") }
end
