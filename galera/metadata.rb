maintainer       "Severalnines AB"
maintainer_email "support@severalnines.com"
license          "Apache 2.0"
description      "Installs a MySQL Galera Node"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recipe "galera", "Installs a MySQL Galera node"

%w{ debian ubuntu centos fedora redhat }.each do |os|
  supports os
end
