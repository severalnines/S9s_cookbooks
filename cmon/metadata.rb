maintainer "Severalnines AB"
maintainer_email "support@severalnines.com"
license "Apache 2.0"
description "Installs and configures cmon controller and agent"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version "0.1"
recipe "cmon", "Includes the cmon agent"
recipe "cmon::agent", "Installs cmon agent"
recipe "cmon::controller", "Installs cmon controller"
recipe "cmon::web", "Installs cmon web application"
recipe "cmon::agent_packages", "Installs cmon agent required packages (psmisc libaio)"
recipe "cmon::controller_packages", "Installs cmon controller requried packages (rrdtool mysql mysql-server)"
recipe "cmon::web_packages", "Installs cmon web application required packages (apache2 php5-mysql php5-gd libapache2-mod-php5)"

%w{ debian ubuntu centos fedora redhat }.each do |os|
  supports os
end