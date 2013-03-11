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

* Ubuntu 12.04 w/ Chef-server v10.16.2.
* Ubuntu 11.10 w/ Chef-solo and Chef-server v0.10.8.

Cookbooks
---------
N/A

Resources and Providers
=======================
N/A

Attributes
==========
The cmon controller recipe uses apt/yum packages and it should not be neccssary to change a many of the attribtues besides specifying a 'root_password' and some MySQL settings like the InnoDB buffer pool etc.

Use role overrides for changing for example the MySQL root password to be different than for the cmon controller's or the location of the MySQL installation for the agents.

    override_attributes({
      "cmon_mysql" => {
                  "install_dir" => "/usr/local",
                  "mysql_bin" => "/usr/local/mysql/bin/mysql",
                  "root_password" => "password"}
       }
    )

* node['cmon_mysql']['root_password']  - Monitored MySQL root password (password)

* node['controller']['mysql_user']     - cmon controller MySQL user (cmon)
* node['controller']['mysql_password'] - cmon controller MySQL user's password (cmon)
* node['controller']['mysql_hostname'] - cmon controller MySQL hostname (nnn)
* node['controller']['mysql_port']     - cmon controller MySQL port (3306)
* node['cmon_password']                - cmon controller user's password (cmon)

* node['agent']['mysql_user']     - agent's MySQL user (cmon)
* node['agent']['mysql_password'] - agent user's password (cmon)
* node['agent']['mysql_hostname'] - monitored MySQL server hostname (127.0.0.1)
* node['agent']['mysql_port']     - monitored MySQL port (3306)
* node['mysql']['root_password'] - Monitored MySQL root password (password)

* node['install_dir_cmon']                                = "/usr/local"
* node['cmon_mysql']['install_dir']                       = "/"
* node['cmon_mysql']['basedir']                           = "/usr"
* node['cmon_mysql']['datadir']                           = "/var/lib/mysql"

* node['cmon_mysql']['innodb']['buffer_pool_size']        = "256M"
* node['cmon_mysql']['innodb']['flush_log_at_trx_commit'] = 2
* node['cmon_mysql']['innodb']['file_per_table']          = 1
* node['cmon_mysql']['innodb']['doublewrite']             = 0
* node['cmon_mysql']['innodb']['log_file_size']           = "512M"
* node['cmon_mysql']['innodb']['log_files_in_group']      = 2
* node['cmon_mysql']['innodb']['buffer_pool_instances']   = 1
* node['cmon_mysql']['innodb']['max_dirty_pages_pct']     = 75
* node['cmon_mysql']['innodb']['thread_concurrency']      = 0
* node['cmon_mysql']['innodb']['concurrency_tickets']     = 5000
* node['cmon_mysql']['innodb']['thread_sleep_delay']      = 10000
* node['cmon_mysql']['innodb']['lock_wait_timeout']       = 50
* node['cmon_mysql']['innodb']['io_capacity']             = 200
* node['cmon_mysql']['innodb']['read_io_threads']         = 4
* node['cmon_mysql']['innodb']['write_io_threads']        = 4

* node['cmon_mysql']['innodb']['file_format']             = "barracuda"
* node['cmon_mysql']['innodb']['flush_method']            = "O_DIRECT"

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
      "type": "galera",
      "cmon_tarball_x86_64": "cmon-1.1.35c-64bit-glibc23-mc70.tar.gz",
      "cmon_tarball_i686": "cmon-1.1.35c-32bit-glibc23-mc70.tar.gz",
      "cmon_tarball_i386": "cmon-1.1.35c-32bit-glibc23-mc70.tar.gz",
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
* **cc_pub_key** is a place holder for the public ssh key (/root/.ssh/id_rsa) which is generated on the ClusterControl controller host. During installation of the agents this key will be added to authorized_keys on the servers. 
You need to paste in the public key here before deploying agents.

Usage
=====

    Roles:
     Controller Role: cc_controller
        run_list [
          "recipe[cmon::controller_mysql]",
          "recipe[cmon::controller_rrdtool]",
          "recipe[cmon::controller]"
        ]

Installs the ClusterControl Controller, standard MySQL server to store cluster data and statistics and rrdtool to create graphs.
Instead of our MySQL recipe you could choose to try any other available MySQL recipe instead.

    Web App Role: cc_webapp
        run_list [
          "recipe[cmon::webserver]", 
          "recipe[cmon::webapp]"
        ]

Installs the ClusterControl web application and apache on the Controller node.

    Agent Role: cc_agent
        run_list [
          "recipe[cmon::agent_packages]",
          "recipe[cmon::agent]"
        ]

Installs the ClusterControl agent. It requires the MySQL root password in order to setup grants correctly on the monitored MySQL server.


Change History
===============

* v0.5 - Cleanup/fixes and tested with Chef 10.16.2, only tested with our galera cookbook
* v0.4 - Fixes for Chef 0.10.10 and working with our galera cookbook
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
