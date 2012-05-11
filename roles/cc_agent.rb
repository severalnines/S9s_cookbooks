name "cc_agent"
description "ClusterControl Agent"
run_list ["recipe[cmon::agent_packages]", "recipe[cmon::agent]"]
