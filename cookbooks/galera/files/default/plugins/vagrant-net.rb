# borrowed from https://gist.github.com/2050259

provide "ipaddress"
require_plugin "#{os}::network"
network["interfaces"]["eth1"]["addresses"].each do |ip, params|
  if params['family'] == ('inet')
    ipaddress ip
  end
end

