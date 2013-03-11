#
# Cookbook Name:: cmon
# Recipe:: webserver
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

install_flag = "/root/.s9s_webserver_installed"
# Install dependency packages
packages = node['web']['packages']
packages.each do |name|
  package name do
    action :install
    options "--force-yes"
  end
end

execute "set-allow-override" do
  command "sed -i 's/AllowOverride None/AllowOverride All/g' #{node['apache']['default-site']}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end

case node['platform']
when 'centos', 'redhat', 'fedora'
  execute "enable-httpd-to-connect-db" do
    command "/usr/sbin/setsebool -P httpd_can_network_connect_db on"
    action :run
    not_if { FileTest.exists?("#{install_flag}") }
  end
end

service "#{node['apache']['service_name']}" do
  action :restart
  not_if { FileTest.exists?("#{install_flag}") }
end

execute "s9s-webserver-installed" do
  command "touch #{install_flag}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end
