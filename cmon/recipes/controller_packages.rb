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
packages = node['cmon']['controller']['packages']
packages.each do |name|
  package name do
    Chef::Log.info "Installing #{name}..."
    action :install
  end
end

# MySQL installed with no root password!
# Let's secure it. Get root password from ['cmon']['local']['mysql_password']
# todo: maybe erb or tmp file
bash "secure-mysql" do
  user "root"
  code <<-EOH
  #{node['cmon']['mysql']['bin_dir']}/mysql -uroot -e "UPDATE mysql.user SET Password=PASSWORD('#{node['cmon']['local']['mysql_password']}') WHERE User='root'"
  #{node['cmon']['mysql']['bin_dir']}/mysql -uroot -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
  #{node['cmon']['mysql']['bin_dir']}/mysql -uroot -e "DROP DATABASE test;DELETE FROM mysql.db WHERE DB='test' OR Db='test\\_%;"
  #{node['cmon']['mysql']['bin_dir']}/mysql -uroot -e "FLUSH PRIVILEGES"
  EOH
end
