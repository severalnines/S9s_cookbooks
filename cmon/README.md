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

* Ubuntu 11.10

Cookbooks
---------
N/A

Resources and Providers
=======================
N/A

Attributes
==========

TODO

* `cmon['remote']['mysql_user']`     - cmon controller MySQL user (cmon)
* `cmon['remote']['mysql_hostname']` - cmon controller MySQL hostname (nnn)
* `cmon['remote']['mysql_password']` - cmon controller MySQL user's password (cmom)
* `cmon['remote']['mysql_port']`     - cmon controller MySQL port (3306)

* `cmon['cmon_password']`        = cmon controller user's password (cmon)
* `cmon['mode']['agent']`        = run as agent
* `cmon['mode']['controller']`   = run as controller
* `cmon['mode']['dual']`         = run in dual mode, i.e., both as controller and agent

* `cmon['local']['mysql_user']`     - MySQ local user (root)
* `cmon['local']['mysql_hostname']` - MySQL local hostname (nnn)
* `cmon['local']['mysql_password']` - MySQL local user's password (cmom)
* `cmon['local']['mysql_port']`     - MySQL local port (3306)

Usage
=====

On agent nodes,

    include_recipe "cmon::agent"
    include_recipe "cmon::agent_packages"

This will install the cmon agent and its requried packages on the node.
After the installation you still need to manually edit the /etc/cmon.cnf file and
enter the correct IP adress to the cmon controller's DB instance.

On controller nodes,

    include_recipe "cmon::controller"
    include_recipe "cmon::controller_packages"

This will install the cmon controller and its requried packages on the node. A cmon user
and its grants will be automatically created using the generated
/usr/local/cmon/etc/cmon_grants.sql file.

On the cmon web application node,

    include_recipe "cmon::web"
    include_recipe "cmon::web_packages"

This will install the cmon web application and its requried packages on the node. 

License and Author
==================

Author:: Alex Yu (<alex@severalnines.com>)

Copyright:: 2012 Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
