Clustercontrol Cookbook
=======================

Installs ClusterControl for your new database node/cluster deployment or on top of your existing database node/cluster. ClusterControl is a management and automation software for database clusters. It helps deploy, monitor, manage and scale your database node/cluster.

Supported database clusters:

- Galera Cluster for MySQL
- Percona XtraDB Cluster
- MariaDB Galera Cluster
- MySQL/MariaDB Replication
- MySQL/MariaDB single instance
- MySQL Cluster (NDB)
- MongoDB Replica Set
- MongoDB Sharded Cluster
- PostgreSQL Streaming Replication

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
- CentOS 8
- Ubuntu 12.04
- Ubuntu 14.04
- Ubuntu 16.04
- Ubuntu 18.04
- Debian 7
- Debian 8
- Debian 9
- Debian 10

Make sure you meet the following criteria prior to the deployment:

- ClusterControl node must run on a clean dedicated host with internet connection.
- If you want to add an existing cluster, ensure your database cluster is up and running.
- SELinux/AppArmor must be turned off. Services or ports to be enabled are listed [here](https://severalnines.com/docs/requirements.html#firewall-and-security-groups).

Attributes
----------

Please refer to `attributes/default.rb`

Data Bags
---------

Data items are used by the recipe to configure SSH public key on database hosts, grants cmon database user and setting up CMON configuration file. We provide a helper script located under `clustercontrol/files/default/s9s_helper.sh`. Please run this script prior to the deployment.

### Helper script - s9s_helper.sh

```bash
$ cd ~/chef-repo/cookbooks/clustercontrol/files/default
$ ./s9s_helper.sh
==============================================
Helper script for ClusterControl Chef cookbook
==============================================

ClusterControl will install a MySQL server and setup the MySQL root user.
Enter the password for MySQL root user [default: 's3cr3tcc'] : R00tP4ssw0rd

ClusterControl will create a MySQL user called 'cmon' for automation tasks.
Enter the password for user cmon [default: 's3cr3tcc'] : Bj990sPkj

ClusterControl will need a sudo user (from ClusterControl to all managed nodes) to perform automation tasks via SSH.
Enter the SSH user [default: root] : dbadmin

Generating config.json..
{
    "id" : "config",
    "mysql_root_password" : "R00tP4ssw0rd",
    "cmon_password" : "Bj990sPkj",
    "cmon_ssh_user" : "dbadmin",
    "cmon_user_home" : "/home/dbadmin",
    "clustercontrol_api_token" : "fe74e6d6918b71a48eb039e495b68b41d19e49ad"
}

Data bag file generated at /home/vagrant/.chef/cookbooks/clustercontrol/files/default/config.json
To upload the data bag, you can use following command:
$ knife data bag create clustercontrol
$ knife data bag from file clustercontrol /home/vagrant/.chef/cookbooks/clustercontrol/files/default/config.json

Reupload the cookbook since it contains a newly generated SSH key:
$ knife cookbook upload clustercontrol
```

Answer all questions and at the end of the wizard, it will generate a data bag file called `config.json` and a set of command that you can use to create and upload the data bag. If you run the script for the first time, it will ask to re-upload the cookbook since it contains a newly generated SSH key:

```bash
$ knife data bag create clustercontrol
Created data_bag[clustercontrol]
 
$ knife data bag from file clustercontrol /home/ubuntu/chef-repo/cookbooks/clustercontrol/files/default/config.json
Updated data_bag_item[clustercontrol::config]
 
$ knife cookbook upload clustercontrol
Uploading clustercontrol [0.1.8]
Uploaded 1 cookbook.
```


*We highly recommend you to use encrypted data bag since it contains confidential information*

Then, create a role, cc_controller:

```ruby
$ cat cc_controller.rb
name "cc_controller"
description "ClusterControl Controller"
run_list ["recipe[clustercontrol]"]
```

Add the defined roles into Chef Server:

```bash
$ knife role from file cc_controller.rb
Updated Role cc_controller!
```

Assign the roles to the relevant nodes:

```bash
$ knife node run_list add clustercontrol.domain.com "role[cc_controller]"
```

Finally, on the client side (ClusterControl host), apply the cookbook:

```bash
$ sudo chef-client
```

### ClusterControl general options

Following options are used for the general ClusterControl set up:

`id`

- The data item identifier. Do not change this value.

`cmon_password`

- Specify the MySQL password for user cmon. The recipe will grant this user with specified password, and is required by ClusterControl.
- Default: 's3cr3tcc'

`mysql_root_password`

- Specify the MySQL root password. This recipe will install a fresh MySQL server and it will create a MySQL user.
- Default: 's3cr3tcc'

`clustercontrol_api_token`

- 40-character ClusterControl token generated from s9s\_helper script.
- Example: 'b7e515255db703c659677a66c4a17952515dbaf5'

`cmon_ssh_user`

- SSH user that will be used by ClusterControl to connect to all managed nodes. This user must be able to escalate as super-user.
- Default: 'root'

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

** Do not forget to generate databag before the deployment begins! Once the cookbook is applied to all nodes, open ClusterControl web UI at `https://[ClusterControl IP address]/clustercontrol` and create the default admin user with a valid email address.


License and Authors
-------------------
Ashraf Sharif (ashraf@severalnines.com) Derived from Opscode, Inc cookbook recipes examples.

Copyright (c) 2014 Severalnines AB.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

`http://www.apache.org/licenses/LICENSE-2.0`

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Please report bugs or suggestions via our support channel: [https://support.severalnines.com](https://support.severalnines.com)
