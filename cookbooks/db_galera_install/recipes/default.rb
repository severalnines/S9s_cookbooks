#
# Cookbook:: db_galera_install
# Recipe:: default
# Author:: Paul Namuag <paul@severalnines.com>
#
# Copyright:: 2019, SeveralNines, All Rights Reserved.



galera_cluster_name = "#{node['cmon']['galera_cluster_name']}"
s9s_bin = "#{node['cmon']['s9s_bin']}"
url_api = "#{node['cmon']['url_api']}"

cc_config = data_bag_item('clustercontrol','config')
db_pass = cc_config['mysql_root_password']


bash "install-galera-nodes" do
  user "root"
  ## Replace the --nodes="<ip1,ip2,ip3..>" to your target node actual IP's/hostname.
  ## Replace --vendor to your desired vendor and --provider-version to the target version
  code <<-EOH
  #{s9s_bin} cluster --create --cluster-type=galera --nodes="192.168.70.70,192.168.70.80,192.168.70.100" \
    --vendor=percona \
    --provider-version=5.7 \
    --db-admin-passwd='#{db_pass}' \
    --os-user=vagrant \
    --cluster-name='#{galera_cluster_name}' \
    --wait \
    --log
  EOH

  not_if "[[ ! -z $(#{s9s_bin} cluster --list --cluster-format='%I' --cluster-name '#{galera_cluster_name}') ]]"
end
