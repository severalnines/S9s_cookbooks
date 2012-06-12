Description
===========
Installs a Codership's MySQL Galera cluster node.

This cookbook should be used initially for development/tests and not in production. 

It currently does not handle a full cluster restart properly by itself, i.e., it does 
not select a node that has the most recent committed transactions as the donor.
You might end up loosing data if the wrong node becomes the donor node.

You can deploy ClusterControl which is able to select a correct node to use when doing a 
complete cluster restart.

Howto: Chef, MySQL Galera and ClusterControl
http://support.severalnines.com/entries/21453521-opscode-s-chef-mysql-galera-and-clustercontrol

Requirements
============

Platform
--------
* Debian, Ubuntu
* CentOS, Red Hat, Fedora

Tested on:

* Ubuntu 11.10/12.04 w/ Chef (Solo) 0.10.8/0.10.10

Attributes
==========

* ['galera']['install_dir'] = "/usr/local"

* ['mysql']['root_password'] = "password"
* ['mysql']['datadir']  = "/var/lib/mysql"
* ['mysql']['innodb']['buffer_pool_size'] = "128M"
* ['mysql']['innodb']['log_file_size'] = "256M"

* ['wsrep']['cluster_name'] = "my_galera_cluster"
* ['wsrep']['slave_threads'] = 1
* ['wsrep']['certify_nonPK'] = 1
* ['wsrep']['max_ws_rows'] = 131072
* ['wsrep']['max_ws_size'] = 1073741824
* ['wsrep']['retry_autocommit'] = 1
* ['wsrep']['auto_increment_control'] = 1
* ['wsrep']['user'] = "wsrep_sst" 
* ['wsrep']['password'] = "wsrep"
* ['wsrep']['sst_method'] = "mysqldump"

and more in attributes/default.rb

Usage
=====

On MySQL Galera Nodes,

		include_recipe "galera:server"

Example cc_galera role:

		name "cc_galera"
		description "MySQL Galera Node"
		run_list "recipe[galera::server]"

Data Bags
=========

s9s_galera / config.json
-------------------------
		{
		  "id": "config",
		  "mysql_wsrep_tarball_x86_64": "mysql-5.5.23_wsrep_23.6-linux-x86_64.tar.gz",
		  "mysql_wsrep_tarball_i686": "mysql-5.5.23_wsrep_23.6-linux-i686.tar.gz",
		  "galera_package_i386": {
		  	"deb": "galera-23.2.1-i386.deb",
		  	"rpm": "galera-23.2.1-1.rhel5.i386.rpm"},  
		  "galera_package_x86_64": {
		  	"deb": "galera-23.2.1-amd64.deb",
		  	"rpm": "galera-23.2.1-1.rhel5.x86_64.rpm"
		  },
		  "mysql_wsrep_source": "https://launchpad.net/codership-mysql/5.5/5.5.23-23.6/+download",
		  "galera_source": "https://launchpad.net/galera/2.x/23.2.1/+download",
		  "sst_method": "mysqldump",
		  "galera_nodes": [
		     "192.168.122.12",
		     "192.168.122.14",
		     "192.168.122.16"
		    ]
		}

* **galera_nodes**  
These are the IP addresses where you have MySQL Galera nodes running and a random host in this list will be used as the cluster URL for a galera node if the galera recipe is "reloaded".
* **sst_method**  
State Snapshot Transfer method, 'mysqldump', 'rsync' or 'rsync_wan'.

Change History
===============

* v0.2 - Use wsrep_urls with mysqld_safe
* v0.1 - Initial recipe based upon MySQL Galera 5.5.23

License and Author
==================

Alex Yu (<alex@severalnines.com>)

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
