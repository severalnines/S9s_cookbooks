Description
===========

Installs and configures cmon controller and agent.

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

No change to these attributes should be required as default.

* ['controller']['mysql_user']     - cmon controller MySQL user (cmon)
* ['controller']['mysql_hostname'] - cmon controller MySQL hostname (nnn)
* ['controller']['mysql_password'] - cmon controller MySQL user's password (cmon)
* ['controller']['mysql_port']     - cmon controller MySQL port (3306)

* ['cmon_password']        = cmon controller user's password (cmon)
* ['mode']['agent']        = run as agent
* ['mode']['controller']   = run as controller
* ['mode']['dual']         = run in dual mode, i.e., both as controller and agent

* ['agent']['mysql_user']     - MySQ local user (root)
* ['local']['mysql_hostname'] - MySQL local hostname (nnn)
* ['local']['mysql_password'] - MySQL local user's password (cmon)
* ['local']['mysql_port']     - MySQL local port (3306)

and others please see attributes/default.rb

Data Bags
=========

Data items are used by the controller recipe to for example add agent hosts 
to its grant table and the agent recipe uses the controller_host_ipaddress to
set the a controller host.

s9s_controller / config.json
----------------------------
{
  "id": "config",
  "controller_host_ipaddress": "192.168.122.11",
  "mode": "controller",
  "cmon_package_x86_64": "cmon-1.1.27-64bit-glibc23-mc70",
  "cmon_package_i686": "cmon-1.1.27-32bit-glibc23-mc70",
  "cmon_package_i386": "cmon-1.1.27-32bit-glibc23-mc70",
  "agent_hosts": [
     "192.168.122.12",
     "192.168.122.14",
     "192.168.122.16"
    ],
  "mysqlserver_hosts": [
     "ip1",
     "ip2"
  ],    
  "datanode_hosts": [
     "ip1",
     "ip2"
  ],    
  "mgm_hosts": [
     "ip1",
     "ip2"
  ]
}

FUTURE: For agentless installations use mysqlserver_hosts, datanode_hosts and mgm_hosts.

Usage
=====

Roles:
 Controller Role: cc_controller
    run_list [
      "recipe[cmon::controller_mysql]", 
      "recipe[cmon::controller_rrdtool]", 
      "recipe[cmon::controller]"
    ]

Installs the Cluster Control Controller process. Instead of our MySQL recipe you can choose to use any other available recipe instead.

Agent Role: cc_agent
    run_list [
      "recipe[cmon::agent_packages]", 
      "recipe[cmon::agent]"
    ]

Web App Role: cc_webapp
    run_list [
      "recipe[cmon::webserver]", 
      "recipe[cmon::webapp]"
    ]

The web application and the webserver are usually installed on the controller node.


Change History
===============

* v0.3 - Code cleanup, better use of roles, data bags and more tests using Chef-Server. Uses cmon v1.1.27.
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
