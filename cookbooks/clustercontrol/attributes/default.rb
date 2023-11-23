
default['api_token'] = ""
default['ssh_user'] = "root"
default['user_home'] = "/root"
## only_cc_v2 {true = if only ccv2, false = if ccv1 and ccv2 combination (the installation setup in 1.9.6 below when ccv2 had been suppported)}
default['only_cc_v2'] = false
## your desired admin email for your clustercontrol setup. Email field will use this as auto-fill value during registration form
default['ccsetup_email'] = "admin@clustercontrol.com"
default['ssh_key'] = "#{node['user_home']}/.ssh/id_rsa"
default['cmon']['mysql_user'] = "cmon"
default['cmon']['mysql_hostname'] = "127.0.0.1"
default['cmon']['mysql_root_password'] = "s3cr3tcc"
default['cmon']['mysql_password'] = "s3cr3tcc"
default['cmon']['mysql_port'] = 3306
default['cmon']['container'] = "NA"
default['mysql']['root_password'] = "password"