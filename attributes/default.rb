#
# Cookbook Name:: graphite
# Attributes:: graphite
#

default['graphite']['debug'] = true

default['graphite']['version'] = "0.9.10"
default['graphite']['password'] = "change_me"
default['graphite']['url'] = "graphite"
default['graphite']['url_aliases'] = []
default['graphite']['listen_port'] = 80
default['graphite']['ssl']['enabled'] = false
default['graphite']['ssl']['cipher_suite'] = "ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP"
default['graphite']['ssl']['certificate_file'] = "/etc/ssl/server.crt"
default['graphite']['ssl']['certificate_key_file'] = "/etc/ssl/server.key"
default['graphite']['base_dir'] = "/opt/graphite"
default['graphite']['doc_root'] = "/opt/graphite/webapp"
default['graphite']['storage_dir'] = "/opt/graphite/storage"
default['graphite']['timezone'] = "America/Los_Angeles"
default['graphite']['django_root'] = "@DJANGO_ROOT@"

default['graphite']['whisper']['uri'] = "https://launchpad.net/graphite/0.9/#{node['graphite']['version']}/+download/whisper-#{node['graphite']['version']}.tar.gz"
default['graphite']['whisper']['checksum'] = "36b5fa917526224678da0a530a6f276d00074f0aa98acd6e2412c79521f9c4ff"

default['graphite']['graphite_web']['uri'] = "https://launchpad.net/graphite/0.9/#{node['graphite']['version']}/+download/graphite-web-#{node['graphite']['version']}.tar.gz"
default['graphite']['graphite_web']['checksum'] = "4fd1d16cac3980fddc09dbf0a72243c7ae32444903258e1b65e28428a48948be"

default['graphite']['carbon']['uri'] = "https://launchpad.net/graphite/0.9/#{node['graphite']['version']}/+download/carbon-#{node['graphite']['version']}.tar.gz"
default['graphite']['carbon']['checksum'] = "4f37e00595b5b078edb9b3f5cae318f752f4446a82623ea4da97dd7d0f6a5072"
default['graphite']['carbon']['line_receiver_interface'] =   "0.0.0.0"
default['graphite']['carbon']['line_receiver_port'] = 2003
default['graphite']['carbon']['pickle_receiver_interface'] = "0.0.0.0"
default['graphite']['carbon']['pickle_receiver_port'] = 2004
default['graphite']['carbon']['cache_query_interface'] =     "0.0.0.0"
default['graphite']['carbon']['cache_query_port'] = 7002
default['graphite']['carbon']['cache_instances'] = 1
default['graphite']['carbon']['max_cache_size'] = "inf"
default['graphite']['carbon']['max_creates_per_second'] = "inf"
default['graphite']['carbon']['max_updates_per_second'] = "1000"
default['graphite']['carbon']['relay']['instances'] = 1
default['graphite']['carbon']['relay']['line_receiver_interface'] = 1
default['graphite']['carbon']['relay']['line_receiver_port'] = 2003
default['graphite']['carbon']['relay']['pickle_receiver_interface'] = "0.0.0.0"
default['graphite']['carbon']['relay']['pickle_receiver_port'] = 2004
default['graphite']['carbon']['relay']['max_datapoints_per_message'] = "500"
default['graphite']['carbon']['relay']['use_flow_control'] = true
default['graphite']['carbon']['relay']['relay_method'] = "consistent-hashing"
default['graphite']['carbon']['relay']['max_queue_size'] = "1000"

default['graphite']['ha_relay']['enable'] = false
default['graphite']['ha_relay']['instances'] = 1
default['graphite']['ha_relay']['enable'] = false
default['graphite']['ha_relay']['line_receiver_port'] = 2103
default['graphite']['ha_relay']['pickle_receiver_port'] = 2104
default['graphite']['ha_relay']['role_name'] = "graphite_cluster_node"
default['graphite']['ha_relay']['servers'] = nil  # List servers to override chef search on role
default['graphite']['ha_relay']['max_queue_size'] = "1000"

default['graphite']['storage_aggregation'] = nil
default['graphite']['storage_schemas'] = [
  {
    'name' => 'catchall', 
    'pattern' => '^.*', 
    'retentions' => '60:100800,900:63000'
  }
]

case node['platform_family']
when "debian","freebsd"
  default['graphite']['carbon']['service_type'] = "runit"
when "rhel","fedora"
  default['graphite']['carbon']['service_type'] = "init"
end
default['graphite']['carbon']['log_whisper_updates'] = "False"

# Default carbon AMQP settings match the carbon default config
default['graphite']['carbon']['enable_amqp'] = false
default['graphite']['carbon']['amqp_host'] = "localhost"
default['graphite']['carbon']['amqp_port'] = 5672
default['graphite']['carbon']['amqp_vhost'] = "/"
default['graphite']['carbon']['amqp_user'] = "guest"
default['graphite']['carbon']['amqp_password'] = "guest"
default['graphite']['carbon']['amqp_exchange'] = "graphite"
default['graphite']['carbon']['amqp_metric_name_in_body'] = false

default['graphite']['encrypted_data_bag']['name'] = nil

default['graphite']['web_server'] = 'apache'
default['graphite']['user_account'] = node['apache']['user']
default['graphite']['group_account'] = node['apache']['group']
default['graphite']['create_user'] = false
default['graphite']['database']['adapter'] = 'sqlite'
default['graphite']['database']['host'] = ''
default['graphite']['database']['port'] = ''
default['graphite']['database']['name'] = 'graphite'
default['graphite']['database']['user'] = ''
default['graphite']['database']['pass'] = ''

default['graphite']['ldap']['enable'] = false
default['graphite']['ldap']['server'] = 'server name'
default['graphite']['ldap']['port'] = '389'
default['graphite']['ldap']['uri'] = 'ldap://server.example.com:389'
default['graphite']['ldap']['search_base'] = 'OU=Employees,DC=hq,DC=rws'
default['graphite']['ldap']['base_user'] = 'CN=read only user,OU=Employees,DC=example,DC=com'
default['graphite']['ldap']['base_pass'] = 'secret'
default['graphite']['ldap']['user_query'] = '(sAMAccountName=%s)'

case node['platform_family']
when "debian"
  default['graphite']['uwsgi_packages'] = %w{uwsgi uwsgi-plugin-python uwsgi-plugin-carbon}
else
  default['graphite']['uwsgi_packages'] = []
end
