#root = File.absolute_path(File.dirname(__FILE__))
path File.expand_path(File.dirname(__FILE__))
cookbook_path "#{File.expand_path(File.dirname(__FILE__))}/cookbooks"
log_level ENV['CHEF_LOG_LEVEL'] && ENV['CHEF_LOG_LEVEL'].downcase.to_sym || :info
log_location ENV['CHEF_LOG_LOCATION'] || STDOUT
verbose_logging ENV['CHEF_VERBOSE_LOGGING']
