name "cc_agent"
description "ClusterControl Agent"
run_list ["recipe[cmon::agent_packages]", "recipe[cmon::agent]"]
#override_attributes({ 
#  "mysql" => {
#              "install_dir" => "/usr/local",
#              "mysql_bin" => "/usr/local/mysql/bin/mysql",
#              "root_password" => "password"}
#   }
#)
