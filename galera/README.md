Description
===========
Installs Codership's MySQL Galera cluster (http://http://www.codership.com/).
Galera Cluster provides synchronous multi-master replication for MySQL (replication plugin).

* No master failover scripting (automatic failover and recovery)
* No slave lag
* Read and write to any node
* Write scalabilty
* WAN Clustering

This cookbook enables you to install a Galera cluster from scratch. At minimum you would probaly only need to change a few attributes like

* ['mysql']['root_password'] = "password"
* ['mysql']['innodb']['buffer_pool_size'] = "256M"

You can also deploy our ClusterControl coookbook with the Galera Cluster which provide additional control and monitoring features.

Howto: Chef, MySQL Galera and ClusterControl
http://support.severalnines.com/entries/21453521-opscode-s-chef-mysql-galera-and-clustercontrol

Requirements
============

Platform
--------
* Debian, Ubuntu
* CentOS, Red Hat, Fedora

Tested on:

* Ubuntu 12.04 w/ Chef-server 10.16.2 and Galera Cluster v2.2
* Ubuntu 11.10/12.04 w/ Chef-solo 0.10.8/0.10.10 and Galera Cluster v2.1

Attributes
==========

* node['galera']['install_dir'] = "/usr/local"
* node['mysql']['root_password'] = "password"

* node['mysql']['basedir'] = "/usr/local"
* node['mysql']['datadir'] = "/var/lib/mysql"
* node['mysql']['rundir']  = "/var/run/mysqld"
* node['mysql']['pid_file'] = /var/lib/mysql/mysqld.pid"
* node['mysql']['socket']  = /var/run/mysqld/mysqld.sock"
* node['mysql']['port']    = 3306
* node['mysql']['tmpdir']  = "/tmp"

* node['mysql']['innodb']['buffer_pool_size'] = "256M"
* node['mysql']['innodb']['flush_log_at_trx_commit'] = 2
* node['mysql']['innodb']['file_per_table'] = 1
* node['mysql']['innodb']['doublewrite'] = 0
* node['mysql']['innodb']['log_file_size'] = "512M"
* node['mysql']['innodb']['log_files_in_group'] = 2
* node['mysql']['innodb']['buffer_pool_instances'] = 1
* node['mysql']['innodb']['max_dirty_pages_pct'] = 75
* node['mysql']['innodb']['thread_concurrency'] = 0
* node['mysql']['innodb']['concurrency_tickets'] = 5000
* node['mysql']['innodb']['thread_sleep_delay'] = 10000
* node['mysql']['innodb']['lock_wait_timeout'] = 50
* node['mysql']['innodb']['io_capacity'] = 200
* node['mysql']['innodb']['read_io_threads'] = 4
* node['mysql']['innodb']['write_io_threads'] = 4

* node['mysql']['innodb']['file_format'] = "barracuda"
* node['mysql']['innodb']['flush_method'] = "O_DIRECT"

* node['wsrep']['cluster_name'] = "my_galera_cluster"
* node['wsrep']['slave_threads'] = 1
* node['wsrep']['certify_nonPK'] = 1
* node['wsrep']['max_ws_rows'] = 131072
* node['wsrep']['max_ws_size'] = 1073741824
* node['wsrep']['retry_autocommit'] = 1

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
		  	"deb": "galera-23.2.2-i386.deb",
		  	"rpm": "galera-23.2.2-1.rhel5.i386.rpm"},
		  "galera_package_x86_64": {
		  	"deb": "galera-23.2.2-amd64.deb",
		  	"rpm": "galera-23.2.2-1.rhel5.x86_64.rpm"
		  },
		  "mysql_wsrep_source": "https://launchpad.net/codership-mysql/5.5/5.5.23-23.6/+download",
		  "galera_source": "https://launchpad.net/galera/2.x/23.2.2/+download",
		  "sst_method": "rsync",
		  "init_node": "192.168.122.12",
		  "galera_nodes": [
		     "192.168.122.12",
		     "192.168.122.14",
		     "192.168.122.16"
		    ],
		   "secure": "yes",
		   "update_wsrep_urls": "no"
		}

* **galera_nodes**
These are the IP addresses where you have MySQL Galera nodes running and a random host in this list will be used as the cluster URL for a galera node if the galera recipe is "reloaded".
* **sst_method**
State Snapshot Transfer method, 'mysqldump', 'rsync' or 'rsync_wan'.

Change History
===============

* v0.3 - Add init_node which specifies the intital donor node.
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
