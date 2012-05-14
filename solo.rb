cookbook_path "#{File.expand_path(File.dirname(__FILE__))}/"
data_bag_path "#{File.expand_path(File.dirname(__FILE__))}/cmon/data_bags"
Chef::Log.debug Chef::Config[:cookbook_path]
Chef::Log.debug Chef::Config[:data_bag_path]

log_level ENV['CHEF_LOG_LEVEL'] && ENV['CHEF_LOG_LEVEL'].downcase.to_sym || :info
log_location ENV['CHEF_LOG_LOCATION'] || STDOUT
verbose_logging ENV['CHEF_VERBOSE_LOGGING']
