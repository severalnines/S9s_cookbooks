clustercontrol Cookbook
=======================

Installs ClusterControl for your new database node/cluster deployment or on top of your existing database node/cluster. ClusterControl is a management and automation software for database clusters. It helps deploy, monitor, manage and scale your database node/cluster.

Supported database clusters:

- Galera Cluster for MySQL
- Percona XtraDB Cluster
- MariaDB Galera Cluster
- MySQL Replication
- MySQL single instance
- MySQL Cluster
- MongoDB Replica Set
- MongoDB Sharded Cluster
- TokuMX Cluster
- PostgreSQL single instance

Details at [Severalnines](http://www.severalnines.com/clustercontrol) website.

This cookbook is a replacement for the deprecated [cmon](https://supermarket.chef.io/cookbooks/cmon) cookbook that we have built earlier. It manages and configures ClusterControl and all of its components:

- Install ClusterControl controller, cmonapi and UI via Severalnines package repository.
- Install and configure MySQL, create CMON DB, grant cmon user and configure DB for ClusterControl UI.
- Install and configure Apache, check permission and install SSL.
- Copy the generated SSH key to all nodes (optional).

If you have any questions, you are welcome to get in touch via our [contact us](http://www.severalnines.com/contact-us) page or email us at [info@severalnines.com](mailto:info@severalnines.com).


Requirements
------------

### Platform

- CentOS, Redhat, Fedora
- Debian, Ubuntu
- x86\_64 architecture only

Tested on Chef Server 11.1/12.0 on following platforms (x86\_64 only):

- CentOS 6.5
- CentOS 7
- Ubuntu 12.04
- Ubuntu 14.04
- Debian 7
- Debian 8

Make sure you meet following criteria prior to the deployment:

- ClusterControl node must run on a clean dedicated host with internet connection.
- If you want to add an existing cluster, ensure your database cluster is up and running.
- If you are running as sudo user, make sure the user is able to escalate to root with sudo command.
- SELinux/AppArmor must be turned off. Services or ports to be enabled are listed [here](http://www.severalnines.com/docs/clustercontrol-administration-guide/administration/securing-clustercontrol).


Attributes
----------

Please refer to `attributes/default.rb`

Data Bags
---------

Data items are used by the ClusterControl controller recipe to configure SSH public key on database hosts, grants cmon database user and setting up CMON configuration file. We provide a helper script located under `clustercontrol/files/default/s9s_helper.sh`. Please run this script prior to the deployment.

### Helper script - s9s_helper.sh
```bash
$ cd ~/chef-repo/cookbooks/clustercontrol/files/default
$ ./s9s_helper.sh
```

Answer all the questions and at the end of the wizard, it will generate a data bag file called `config.json` and a set of command that you can use to create and upload the data bag. If you run the script for the first time, it will ask to re-upload the cookbook since it contains a newly generated SSH key:
```bash
$ knife cookbook upload clustercontrol
```

### Example data bag - clustercontrol/files/default/config.json
```json
{
  "id"                      : "config",
  "cmon_password"           : "cmonP4ss",
  "mysql_root_password"     : "myR00tP4ssword",
  "clustercontrol_api_token": "b7e515255db703c659677a66c4a17952515dbaf5"
}
```

*We highly recommend you to use encrypted data bag since it contains confidential information*

### ClusterControl general options

Following options are used for the general ClusterControl set up:

`id`
The data item identifier. Do not change this value.

`cmon_password`
Specify the MySQL password for user cmon. The recipe will grant this user with specified password, and is required by ClusterControl.
- Default: 'cmon'

`mysql_root_password`
Specify the MySQL root password. This recipe will install a fresh MySQL server and it will create a MySQL user.
- Default: 'password'

`clustercontrol_api_token`
40-character ClusterControl token generated from s9s\_helper script.
- Example: 'b7e515255db703c659677a66c4a17952515dbaf5'


Usage
-----
#### clustercontrol::default, clustercontrol::controller

For ClusterControl host, just include `clustercontrol` or `clustercontrol::controller` in your node's `run_list`:

```json
{
  "name":"clustercontrol_node",
  "run_list": [
    "recipe[clustercontrol]"
  ]
}
```

### clustercontrol::db\_hosts

For database hosts, include `clustercontrol::db_hosts` in your node's `run_list`:

```json
{
  "name":"database_nodes",
  "run_list": [
    "recipe[clustercontrol::db_hosts]"
  ]
}
```

** Do not forget to generate databag before the deployment begins! Once the cookbook is applied to all nodes, open ClusterControl web UI at `https://[ClusterControl IP address]/clustercontrol` and create the default admin user with valid email address.

Limitations
-----------

This module has been tested on following platforms:

- Debian 7 (wheezy)
- Debian 8 (jessie)
- Ubuntu 14.04 LTS (trusty)
- Ubuntu 12.04 LTS (precise)
- RHEL 6/7
- CentOS 6/7


[ClusterControl known issues and limitations](http://www.severalnines.com/docs/clustercontrol-troubleshooting-guide/known-issues-limitations).

Change History
--------------

- v0.1.5 - Tested with ClusterControl v.1.3.1 on Chef 12.
- v0.1.4 - Follow install-cc installation method. Tested with ClusterControl v1.2.11 on Chef 12. Support RHEL/CentOS 7, Debian 8 (Jessie).
- v0.1.3 - Add datadir into s9s\_helper.
- v0.1.2 - Fixed sudoer with password.
- v0.1.1 - Cleaning up and updated README.
- v0.1.0 - Initial recipes based on ClusterControl v1.2.8.

License and Authors
-------------------
Ashraf Sharif (ashraf@severalnines.com) Derived from Opscode, Inc cookbook recipes examples.

Copyright (c) 2014 Severalnines AB.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

`http://www.apache.org/licenses/LICENSE-2.0`

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Please report bugs or suggestions via our support channel: [https://support.severalnines.com](https://support.severalnines.com)
