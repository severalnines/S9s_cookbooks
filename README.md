Clustercontrol Cookbook
=======================

Installs ClusterControl for your new database node/cluster deployment or on top of your existing database node/cluster. ClusterControl is a management and automation software for database clusters. It helps deploy, monitor, manage and scale your database node/cluster.

Since the release of ClusterControl Cookbook 2.0.0 version, this gear towards maximizing the deployment of ClusterControl version 2 (CCv2). The CCv2 does not depend anymore with PHP technology as it is engineered using React (or React.js/ReactJS). Using CCv2 means its lightweight compared to ClusterControl version 1 (CCv1). If you use CCv1, make sure you have `only_cc_v2` parameter is set to *false*. Check out below to about its general options of this cookbook.

Supported database clusters:

- Galera Cluster for MySQL
- Percona XtraDB Cluster
- MariaDB Galera Cluster
- MySQL/MariaDB Replication
- MySQL/MariaDB single instance
- MySQL Cluster (NDB)
- MongoDB Replica Set
- MongoDB Sharded Cluster
- PostgreSQL/TimescaleDB Streaming Replication
- Redis Cluster
- MSSQL Server 2019
- Elasticsearch Cluster

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

- CentOS, Redhat, Fedora, Oracle Linux
- SLES/OpenSUSE
- Debian, Ubuntu
- x86\_64 architecture only

This has been tested on Chef with the most recently versions:

```
root@chefwork:~/chef-repo/cookbooks# chef --version
Chef Workstation version: 24.2.1058
Chef Infra Client version: 18.3.0
Chef InSpec version: 5.22.40
Chef CLI version: 5.6.14
Chef Habitat version: 1.6.652
Test Kitchen version: 3.6.0
Cookstyle version: 7.32.7
```

and tested on Chef Server 
```
root@chefmas:~# chef-server-ctl version
15.9.20
```

Targetted supported platforms are the following:

- RHEL/CentOS/Rocky Linux /AlmaLinux versions 7, 8, and 9
- Suse Enterprise Linux (SLES)/OpenSUSE version 15.x
- Ubuntu 18.04, 20.04, 22.04 (Jammy), and 22.10 (Kinetic--already EOF) 
- Debian 9, 10, 11

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
In every deployment if your ClusterControl using this S9S Cookbooks, make sure that you have properly configured it. Using the `s9s_helper.sh` script, this allows you to properly configure the parameters required to setup your environment.

Below is an example of a successful run using he `s9s_helper.sh` script.
```bash
$ cd ~/chef-repo/cookbooks/clustercontrol/files/default

root@chefwork:~/chef-repo/cookbooks/clustercontrol/files/default# ./s9s_helper.sh
==============================================
Helper script for ClusterControl Chef cookbook
==============================================

ClusterControl will install a MySQL server and setup the MySQL root user.
Enter the password for MySQL root user [default: 's3cr3tcc'] : R00tP@55

ClusterControl will create a MySQL user called 'cmon' for automation tasks.
Enter the password for user cmon [default: 's3cr3tcc'] : cm0nP@55w0rd

ClusterControl will need a sudo user (from ClusterControl to all managed nodes) to perform automation tasks via SSH.
Enter the SSH user [default: root] : vagrant
Your desired ServerName in apache and your hostname in your cmon.
If you have multiple network device and IP addresses in your server, specify here your desired hostname/IP addresses.
Enter your desired IP address or hostname [default: set to FQDN detection by Chef] : 192.168.40.195

Generating config.json..
{
    "id" : "config",
    "mysql_root_password" : "R00tP@55",
    "cmon_password" : "cm0nP@55w0rd",
    "cmon_ssh_user" : "vagrant",
    "cmon_user_home" : "/home/vagrant",
    "cmon_server_host" : "192.168.40.195",
    "clustercontrol_api_token" : "d22d3e7b210ab0dbe04de47afa9408c9a2d41243",
    "clustercontrol_controller_id" : "bb47df956c69a4c24d8e24ce983b30f1be923a30"
}

Data bag file generated at /root/chef-repo/cookbooks/clustercontrol/files/default/config.json
To upload the data bag, you can use following command:
$ knife data bag create clustercontrol
$ knife data bag from file clustercontrol /root/chef-repo/cookbooks/clustercontrol/files/default/config.json

** We highly recommend you to use encrypted data bag since it contains confidential information **
```

As mentioned, you must have to create a data bug to upload it to the Chef server repo. This means, doing that you have to run the following:
```
bash
$ knife data bag create clustercontrol
Created data_bag[clustercontrol]
 
$ knife data bag from file clustercontrol /root/chef-repo/cookbooks/clustercontrol/files/default/config.json
Updated data_bag_item[clustercontrol::config]
 
$ cd /root/chef-repo/cookbooks/
$ knife cookbook upload clustercontrol
Uploading clustercontrol [0.1.8]
Uploaded 1 cookbook.
```

When using the `s9s_helper.sh` script, just make sure that you answer all questions prompted using the script wizard. It will generate a data bag file called `config.json` and a set of command that you can use to create and upload the data bag.

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
where clustercontrol.domain.com is the hostname/FQDN/IP address of your ClusterController node.

Finally, on the client side (ClusterControl host), apply the cookbook:

```bash
$ sudo chef-client
```

Alternatively, you can also run this from the Workstation as follows,
```
bash
$ knife ssh 'name:clustercontrol.domain.com' 'sudo chef-client' -x vagrant
```
where in this example, `vagrant` is my OS user that both exist in my workstation and on the target client node (node to be setup for ClusterControl deployment).

S9s_cookbooks general options
-----

Following options are used for the general ClusterControl data bag set up: (see _files/default/config.json_)

`id`

- The data item identifier. Do not change this value.

`mysql_root_password`

- Specify the MySQL root password. This recipe will install a fresh MySQL server and it will create a MySQL user.
- Default: 's3cr3tcc'

`cmon_password`

- Specify the MySQL password for user cmon. The recipe will grant this user with specified password, and is required by ClusterControl.
- Default: 's3cr3tcc'

`cmon_ssh_user`

- Specify the SSH user to be used for reaching out your client nodes from ClusterControl to your DB nodes. Make sure your SSH user has super and sudo access
- Default: 'root'

`cmon_user_home`

 Specify the SSH user's home directory. This shall be the user's home directory of your OS user from your CC controller node and the DB nodes.
- Default: '/root/'

`cmon_server_host`

 Specify the hostname/FQDN/IP address of your CC controller node.
- Default: 'set to FQDN detection by Chef'

`clustercontrol_api_token`

- 40-character ClusterControl token generated from s9s\_helper script. Do not modify or do anything on this parameter. Let the script handles it for you.
- Example: 'b7e515255db703c659677a66c4a17952515dbaf5'

`clustercontrol_controller_id`

- 40-character ClusterControl token generated from s9s\_helper script. Basically, this is your controller id.
- Example: 'bb47df956c69a4c24d8e24ce983b30f1be923a30'

`only_cc_v2`

- Accepts boolean parameter. Set either *true* or *false*. When set to *true*, this means that only ClusterControl version 2 (CCv2) will be installed and setup. Setting it to *false* will allow both ClusterControl version 1 and CCv2 will be installed. To set this parameter, check the file _attributes/default.rb_ and find the parameter `default['only_cc_v2']`.
- Default: true (only CCv2)

`ccsetup_email`

- Accepts string value. Set your desired e-mail address to be used when and during registration of your user after deployment and installation of ClusterControl. To set this parameter, check the file _attributes/default.rb_ and find the parameter `default['ccsetup_email']`.
- Default: admin@clustercontrol.com
	
	
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


Limitations
-------------------
ClusterControl version 1 UI does not support PHP 8.x version. In fact, there is little hope for improvement here since Severlanines is moving towards ClusterControl version 2 (CCv2). With that regard, this cookbook will automatically setup the PHP 7.x for you which means it downgrades the version of your PHP in the target server where
you want to install ClusterControl.

* Currently, the PHP 7.x that ClusterControl installs is coming from Ondrej's PPA repository for Debian/Ubuntu. For RHEL 9, it uses the remi repository. In case you have doubts of this repository, please review in case of security issues. 
* *For Ubuntu 22.10 (Kinetic--already EOF)*: On the other hand, their current repository also does not support Ubuntu Kinetic (22.10), but this cookbook uses the Jammy version of their repository to allow installation of PHP 7.x version and have it deployed smoothly. This has been tested in Ubuntu Kinetic and works properly. Take note, Ubuntu Kinetic is already EOF so you might not use this version of Ubuntu.


License and Authors
-------------------
Ashraf Sharif (ashraf@severalnines.com)/Paul Namuag (paul@severalnines.com) Derived from Opscode, Inc cookbook recipes examples.

Copyright (c) 2023 Severalnines AB.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

`http://www.apache.org/licenses/LICENSE-2.0`

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Please report bugs or suggestions via our support channel: [https://support.severalnines.com](https://support.severalnines.com)
