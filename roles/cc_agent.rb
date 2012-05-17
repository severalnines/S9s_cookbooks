name "cc_agent"
description "ClusterControl Agent"
run_list ["recipe[cmon::agent_packages]", "recipe[cmon::agent]"]
#override_attributes({ "mysql" => {"install_dir" => "/usr/local"}})
#override_attributes({ "mysql" => {"mysql_bin" => "/usr/local/mysql/bin/mysql"}})