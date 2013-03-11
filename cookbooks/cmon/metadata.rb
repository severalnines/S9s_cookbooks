maintainer "Severalnines AB"
maintainer_email "support@severalnines.com"
license "Apache 2.0"
description "Installs and configures ClusterControl controller and agents"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version "0.5"
recipe "cmon::agent", "Installs the ClusterControl agent"
recipe "cmon::controller", "Installs the ClusterControl controller"
recipe "cmon::controller_mysql", "Installs ClusterControl's MySQL server"
recipe "cmon::controller_rrdtool", "Installs rrdtool to generate grapsh on the controller node"
recipe "cmon::webapp", "Installs the ClusterControl web application"
recipe "cmon::webserver", "Installs Apache2"

%w{ debian ubuntu centos fedora redhat }.each do |os|
  supports os
end