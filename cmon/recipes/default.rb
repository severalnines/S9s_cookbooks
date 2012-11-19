#
# Cookbook Name:: cmon
# Recipe:: default
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

#
# cmon Agent
#
# cmon::agent_packages
#   installs 
#     psmisc libaio (rhel/centos)
#     psmisc libaio1 (debian/ubuntu)
#
# cmon::agent
#   installs the agent

include_recipe "cmon::agent_packages"
include_recipe "cmon::agent"

#
# cmon Controller
#
# cmon::controller_mysql
#   installs 
#     mysql mysql-server (rhel/centos)
#     mysql-server (debian)
#
# cmon::controller_rrdtool
#   installs 
#     rrdtool
#
# cmon::controller
#   installs the controller 

#include_recipe "cmon::controller_mysql"
#include_recipe "cmon::controller_rrdtool"
#include_recipe "cmon::controller"

#
# cmon Web app
#
# cmon::webserver
#   installs
#     httpd php php-mysql php-gd (rhel/centos)
#     apache2 php5-mysql php5-gd (debian/ubuntu)
#
# cmon::webapp
#   installs ClusterControl web application (php)

#include_recipe "cmon::webserver"
#include_recipe "cmon::webapp"
