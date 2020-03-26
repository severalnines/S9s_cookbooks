clustercontrol CHANGELOG
========================

This file is used to list changes made in each version of the clustercontrol cookbook.

0.1.10
------
- 26-Mar-2020
-- Tested with Oracle Enterprise 7
-- Added gpg installation for Debian
-- Added flag checks for MySQL/Apache/CMON to restart only when necessary
-- Removed sql directory after setup

0.1.9
-----
- 16-Mar-2020
-- Updated README

0.1.8
-----
- 16-Mar-2020
-- Tested with ClusterControl 1.7.5 version.
-- Updated the default password values.
-- Added /etc/default/cmon
-- Use s9s.conf and s9s-ssl.conf for RHEL-based servers.
-- Removed all CMONAPI references.
-- Improvements on s9s-helper.sh
-- Support new OSes: RHEL8, Debian 10, Ubuntu 18.04

0.1.7
-----
-- Tested with ClusterControl 1.7.2 version.
-- Fixed some minor bugs where adding a cluster does not shows up in the dashboard due to absence of cmon API configuration in the database
-- Fixed bug when automating an installation of CC then afterwards, automate and create a Cluster. It needs to restart the cmon daemon in order to reload the configuration such as the RPC token into the memory.

0.1.6
----- 
- 16-Jul-2018
-- Tested with ClusterControl v1.6.1 on Chef 12.
-- Added s9s cli installation via package manager
-- Converted node.set to node.override
-- Added cmon-cloud, cmon-ssh, cmon-events

0.1.5
-----
- 7-Jun-2016 - Tested with ClusterControl v1.3.1 on Chef 12.

0.1.4
-----
- 8-Dec-2015 - Follow install-cc installation method. Tested with ClusterControl v1.2.11 on Chef 12. Support RHEL/CentOS 7, Debian 8 (Jessie).

0.1.3
-----
- 19-Dec-2014 - Add datadir into s9s_helper

0.1.2
-----
- 19-Dec-2014 - Fixed sudoer with password

0.1.1
-----
- 19-Dec-2014 - Cleaning up and updated README

0.1.0
-----
- 17-Dec-2014 - Initial recipes based on ClusterControl v1.2.8
