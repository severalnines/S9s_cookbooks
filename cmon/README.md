Description
===========

Installs and configures cmon controller and agent.

Howto: Chef, MySQL Galera and ClusterControl
http://support.severalnines.com/entries/21453521-opscode-s-chef-mysql-galera-and-clustercontrol

Requirements
============

Platform
--------

* Debian, Ubuntu
* CentOS, Red Hat, Fedora

Tested on:

* Ubuntu 11.10 w/ chef-solo and chef-server v0.10.8 only.

Cookbooks
---------
N/A

Resources and Providers
=======================
N/A

Attributes
==========
The cmon controller recipe uses apt/yum packages and there should not be neccssary to change a lof of the attribtues besides specifying a 'root_password'.

Use overrides for changing for example the MySQL root password to be different than for the cmon controller's.

* ['mysql']['root_password'] - Monitored MySQL root password (password)
* ['mysql']['mysql_bin'] = ['mysql']['bin_dir'] + "/mysql"    

* ['controller']['mysql_user']     - cmon controller MySQL user (cmon)
* ['controller']['mysql_password'] - cmon controller MySQL user's password (cmon)
* ['controller']['mysql_hostname'] - cmon controller MySQL hostname (nnn)
* ['controller']['mysql_port']     - cmon controller MySQL port (3306)  

* ['cmon_password']        = cmon controller user's password (cmon)
* ['mode']['agent']        = run as 'agent'
* ['mode']['controller']   = run as 'controller'
* ['mode']['dual']         = run in 'dual' mode, i.e., both as controller and agent  

* ['agent']['mysql_user']     - agent's MySQL user (cmon)
* ['agent']['mysql_password'] - agent user's password (cmon)
* ['agent']['mysql_hostname'] - monitored MySQL server hostname (127.0.0.1)
* ['agent']['mysql_port']     - monitored MySQL port (3306)  
* ['mysql']['root_password'] - Monitored MySQL root password (password)  

* ['mysql']['data_dir']  = "/var/lib/mysql"  

and others please see attributes/default.rb

Data Bags
=========

Data items are used by the controller recipe to for example add agent hosts 
to its grant table and the agent recipe uses the controller_host_ipaddress to
set a controller host.

s9s_controller / config.json
----------------------------
    {
      "id": "config",
      "controller_host_ipaddress": "192.168.122.11",
      "mode": "controller",
      "type": "replication",
      "cmon_tarball_x86_64": "cmon-1.1.27-64bit-glibc23-mc70.tar.gz",
      "cmon_tarball_i686": "cmon-1.1.27-32bit-glibc23-mc70.tar.gz",
      "cmon_tarball_i386": "cmon-1.1.27-32bit-glibc23-mc70.tar.gz",
      "cmon_source": "http://www.severalnines.com/downloads/cmon",
      "cc_pub_key": "",
      "agent_hosts": [
         "192.168.122.12",
         "192.168.122.14",
         "192.168.122.16"
        ]
    }
  
* **controller_host_ipaddress** The controller's IP address.    
* **agent_hosts** is a list of agents that is deployed. This list is used to setup grants for the agents.  
* **cc_pub_key** is a place holder for the public ssh key which is generated on the ClusterControl controller host. The agent hosts will have this key authorized to access its server. You would paste in the public key here before deploying agents.

Usage
=====

    Roles:
     Controller Role: cc_controller
        run_list [
          "recipe[cmon::controller_mysql]", 
          "recipe[cmon::controller]"
        ]

Installs the ClusterControl Controller and a MySQL server to store our monitoring data. 
Instead of our MySQL recipe you could choose to try any other available MySQL recipe instead.

    Agent Role: cc_agent
        run_list [
          "recipe[cmon::agent_packages]", 
          "recipe[cmon::agent]"
        ]

Installs the ClusterControl agent. It requires a MySQL root password in order to setup grants correctly on the monitored MySQL server. 

    Web App Role: cc_webapp
        run_list [
          "recipe[cmon::webserver]", 
          "recipe[cmon::webapp]"
        ]

The ClusterControl web application and a webserver are usually installed on the controller node.


Change History
===============

* v0.4 - Fixes for Chef 0.10.10 and working with galera cookbook
* v0.3 - Code cleanup, better use of roles, data bags and more tests using Chef-Server 0.10.8.
* v0.2 - Bug fixes and making sure it worked on Chef-Solo.
* v0.1 - Initial recipes based upon cmon v1.1.25. 

License and Author
==================

Alex Yu (<alex@severalnines.com>)
Derived from Opscode, Inc cookbook recipes examples.

Copyright (c) 2012 Severalnines AB.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
