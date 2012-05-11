name "cc_webapp"
description "ClusterControl Web Application"
run_list ["recipe[cmon::webserver]", "recipe[cmon::webapp]"]
