#
# Cookbook Name:: graphite
# Recipe:: carbon
#
# Copyright 2011, Heavy Water Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform']
when "freebsd"
  package "py-twisted"
  package "py-simplejson"
else
  package "python-twisted"
  package "python-simplejson"
end

if node['graphite']['carbon']['enable_amqp']
  include_recipe "python::pip"
  python_pip "txamqp" do
    action :install
  end
end

version = node['graphite']['version']
pyver = node['languages']['python']['version'][0..-3]

remote_file "#{Chef::Config[:file_cache_path]}/carbon-#{version}.tar.gz" do
  source node['graphite']['carbon']['uri']
  checksum node['graphite']['carbon']['checksum']
end

execute "untar carbon" do
  command "tar xzf carbon-#{version}.tar.gz"
  creates "#{Chef::Config[:file_cache_path]}/carbon-#{version}"
  cwd Chef::Config[:file_cache_path]
end

execute "install carbon" do
  command "python setup.py install --prefix=#{node['graphite']['base_dir']} --install-lib=#{node['graphite']['base_dir']}/lib"
  creates "#{node['graphite']['base_dir']}/lib/carbon-#{version}-py#{pyver}.egg-info"
  cwd "#{Chef::Config[:file_cache_path]}/carbon-#{version}"
end

case node['graphite']['carbon']['service_type']
when "runit"
  carbon_cache_service_resource = "runit_service[carbon-cache]"
  carbon_relay_service_resource = "runit_service[carbon-relay]"
  carbon_ha_relay_service_resource = "runit_service[carbon-relay-ha]"
else
  carbon_cache_service_resource = "service[carbon-cache]"
  carbon_relay_service_resource = "service[carbon-relay]"
  carbon_ha_relay_service_resource = "service[carbon-relay-ha]"
end

if node['graphite']['ha_relay']['enable']
  if node['graphite']['ha_relay']['instances'] > 1
    node['graphite']['ha_relay']['instances'].times do |i|
      execute "add ifconfig lo0 127.0.1.#{1+i}" do
        command "ifconfig lo0 alias 127.0.1.#{1+i} netmask 255.255.255.255"
        action :run
      end
    end
  end
  if node['graphite']['ha_relay']['servers'].nil? and !Chef::Config[:solo]
    ha_relay_servers = search("node","roles:#{node['graphite']['ha_relay']['role_name']} AND chef_environment:#{node.chef_environment}").map{|n| "#{n.ipaddress}:#{node['graphite']['carbon']['relay']['pickle_receiver_port']}" }
  else
    ha_relay_servers = node['graphite']['ha_relay']['servers']
  end
else
  ha_relay_servers = []
end

if node['graphite']['carbon']['relay']['instances'] > 1
  node['graphite']['carbon']['relay']['instances'].times do |i|
    execute "add ifconfig lo0 127.0.2.#{1+i}" do
      command "ifconfig lo0 alias 127.0.2.#{1+i} netmask 255.255.255.255"
      action :run
    end
  end
end

template "#{node['graphite']['base_dir']}/conf/carbon.conf" do
  owner node['graphite']['user_account']
  group node['graphite']['group_account']
  variables( :line_receiver_interface => node['graphite']['carbon']['line_receiver_interface'],
             :line_receiver_port => node['graphite']['carbon']['line_receiver_port'],
             :pickle_receiver_interface => node['graphite']['carbon']['pickle_receiver_interface'],
             :pickle_receiver_port => node['graphite']['carbon']['pickle_receiver_port'],
             :cache_query_interface => node['graphite']['carbon']['cache_query_interface'],
             :cache_query_port => node['graphite']['carbon']['cache_query_port'],
             :cache_instances => node['graphite']['carbon']['cache_instances'],
             :max_cache_size => node['graphite']['carbon']['max_cache_size'],
             :max_updates_per_second => node['graphite']['carbon']['max_updates_per_second'],
             :max_creates_per_second => node['graphite']['carbon']['max_creates_per_second'],
             :log_whisper_updates => node['graphite']['carbon']['log_whisper_updates'],
             :enable_amqp => node['graphite']['carbon']['enable_amqp'],
             :amqp_host => node['graphite']['carbon']['amqp_host'],
             :amqp_port => node['graphite']['carbon']['amqp_port'],
             :amqp_vhost => node['graphite']['carbon']['amqp_vhost'],
             :amqp_user => node['graphite']['carbon']['amqp_user'],
             :amqp_password => node['graphite']['carbon']['amqp_password'],
             :amqp_exchange => node['graphite']['carbon']['amqp_exchange'],
             :amqp_metric_name_in_body => node['graphite']['carbon']['amqp_metric_name_in_body'],
             :relay_max_datapoints_per_message => node['graphite']['carbon']['relay']['max_datapoints_per_message'],
             :relay_use_flow_control => node['graphite']['carbon']['relay']['use_flow_control'],
             :relay_relay_method => node['graphite']['carbon']['relay']['relay_method'],
             :relay_max_queue_size => node['graphite']['carbon']['relay']['max_queue_size'],
             :relay_instances => node['graphite']['carbon']['relay']['instances'],
             :relay_line_receiver_interface => node['graphite']['carbon']['relay']['line_receiver_interface'],
             :relay_line_receiver_port => node['graphite']['carbon']['relay']['line_receiver_port'],
             :relay_pickle_receiver_interface => node['graphite']['carbon']['relay']['pickle_receiver_interface'],
             :relay_pickle_receiver_port => node['graphite']['carbon']['relay']['pickle_receiver_port'],
             :ha_relay_enable => node['graphite']['ha_relay']['enable'],
             :ha_relay_instances => node['graphite']['ha_relay']['instances'],
             :ha_relay_line_receiver_port => node['graphite']['ha_relay']['line_receiver_port'],
             :ha_relay_pickle_receiver_port => node['graphite']['ha_relay']['pickle_receiver_port'],
             :ha_relay_max_queue_size => node['graphite']['ha_relay']['max_queue_size'],
             :ha_relay_servers => ha_relay_servers.sort,
             :storage_dir => node['graphite']['storage_dir'])
  if node['graphite']['carbon']['cache_instances'] > 1
    index = 'a'
    node['graphite']['carbon']['cache_instances'].times do
      notifies :restart, carbon_cache_service_resource.gsub(/carbon-cache/, "carbon-cache-#{index}")
      index = index.next
    end
    if node['graphite']['carbon']['relay']['instances'] > 1
      index = 'a'
      node['graphite']['carbon']['relay']['instances'].times do |i|
        notifies :restart, carbon_relay_service_resource.gsub(/carbon-relay/, "carbon-relay-#{index}")
        index = index.next
      end
    else
      notifies :restart, carbon_relay_service_resource
    end
  else
    notifies :restart, carbon_cache_service_resource
  end
  if node['graphite']['ha_relay']['enable']
    if node['graphite']['ha_relay']['instances'] > 1
      index = 'a'
      node['graphite']['ha_relay']['instances'].times do |i|
        notifies :restart, carbon_ha_relay_service_resource.gsub(/carbon-relay-ha/, "carbon-relay-ha-#{index}")
        index = index.next
      end
    else
      notifies :restart, carbon_ha_relay_service_resource
    end
  end
end

if node['graphite']['ha_relay']['enable']
  template "#{node['graphite']['base_dir']}/conf/relay-rules.conf" do
    source 'relay-rules.conf.erb'
    owner node['graphite']['user_account']
    group node['graphite']['group_account']
    variables({:servers => ha_relay_servers})
    only_if { ha_relay_servers.is_a?(Array) }
  end
end

%w{ schemas aggregation }.each do |storage_feature|
  storage_config = node['graphite']['storage_' + storage_feature]

  template "#{node['graphite']['base_dir']}/conf/storage-#{storage_feature}.conf" do
    source 'storage.conf.erb'
    owner node['graphite']['user_account']
    group node['graphite']['group_account']
    variables({:storage_config => storage_config})
    only_if { storage_config.is_a?(Array) }
  end
end

directory node['graphite']['storage_dir'] do
  owner node['graphite']['user_account']
  group node['graphite']['group_account']
  recursive true
end

%w{ log whisper }.each do |dir|
  directory "#{node['graphite']['storage_dir']}/#{dir}" do
    owner node['graphite']['user_account']
    group node['graphite']['group_account']
  end
end

directory "#{node['graphite']['base_dir']}/lib/twisted/plugins/" do
  owner node['graphite']['user_account']
  group node['graphite']['group_account']
  recursive true
end

service_type = node['graphite']['carbon']['service_type']
include_recipe "#{cookbook_name}::#{recipe_name}_#{service_type}"
