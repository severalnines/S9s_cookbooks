#
# Cookbook Name:: cmon
# Recipe:: controller-packages
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
packages = node['controller']['packages']
packages.each do |name|
  package name do
    Chef::Log.info "Installing #{name}..."
    action :install
    options "--force-yes"
  end
end

# MySQL installed with no root password!
# Let's secure it. Get root password from ['cmon']['local']['mysql_password']
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
