execute "controller-install-privileges" do
  command "#{node['mysql']['mysql_bin']} -uroot -p#{node['mysql']['root_password']} < #{node['sql']['controller_grants']}"
  action :nothing
  not_if { FileTest.exists?("#{install_flag}") }
end

template "cmon.controller.grants.sql" do
  path "#{node['sql']['controller_grants']}"
  source "cmon.controller.grants.sql.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :run, resources(:execute => "controller-install-privileges"), :immediately
end


agents = data_bag_item('s9s_controller', 'config')
hosts = agents['agent_hosts']
host_list = ""
hosts.each do |h|
 host_list << h + " "
end

bash "create-agent-grants" do
  user "root"
  code <<-EOH
    for h in #{host_list}
    do
      echo "GRANT SUPER ON *.* TO 'cmon'@'$h' IDENTIFIED BY '#{node['cmon_password']}';" >> #{node['sql']['controller_agent_grants']}
      echo "GRANT INSERT,UPDATE,DELETE,SELECT ON cmon.* TO 'cmon'@'$h' IDENTIFIED BY '#{node['cmon_password']}';" >> #{node['sql']['controller_agent_grants']}
    done
  EOH
  not_if { FileTest.exists?(node['sql']['controller_agent_grants']) }  
end

execute "controller-grant-agents" do
  command "#{node['mysql']['mysql_bin']} -uroot -p#{node['mysql']['root_password']} < #{node['sql']['controller_agent_grants']}"
  action :run
  not_if { FileTest.exists?("#{install_flag}") }
end

service "cmon" do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :nothing
end 

template "cmon.controller.cnf" do
  path "#{node['install_config_path']}/cmon.cnf"
  source "cmon.controller.cnf.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "cmon")
end

cookbook_file "/etc/init.d/cmon" do
  backup false
  owner "root"
  group "root"
  mode "0755"
  source "etc/init.d/cmon"
  notifies :restart, resources(:service => "cmon")
end

service "cmon" do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [:enable, :start]
end
