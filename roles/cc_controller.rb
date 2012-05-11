name "cc_controller"
description "ClusterControl Controller"
run_list ["recipe[cmon::controller_mysql]", "recipe[cmon::controller_rrdtool]", "recipe[cmon::controller]"]

