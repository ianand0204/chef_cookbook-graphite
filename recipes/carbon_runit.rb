#
# Cookbook Name:: graphite
# Recipe:: carbon_runit
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

include_recipe "runit"

def cleanup_service(service_name)
  runit_service service_name do
    action :disable
    only_if { ::Dir.exists?(::File.join(node['runit']['sv_dir'],service_name)) }
  end
  directory ::File.join(node['runit']['sv_dir'],service_name) do
    action :delete
    recursive true
    only_if { ::Dir.exists?(::File.join(node['runit']['sv_dir'],service_name)) }
  end
end

def cleanup_unmapped_services(service_prefix='carbon-cache-',mapped_instances=[])
  services = ::Dir.glob(::File.join(node['runit']['sv_dir'],'*')).map{|i|File.basename(i).gsub(/#{service_prefix}[a-z]$/,'')}
  (services-mapped_instances).each do |service_instance|
    cleanup_service("#{service_prefix}#{service_instance}")
  end
end

if node['graphite']['carbon']['cache_instances'] > 1

  mapped_cache_instances = []
  index = 'a'
  node['graphite']['carbon']['cache_instances'].times do |i|
    mapped_cache_instances << index
    runit_service "carbon-cache-#{index}" do
      template_name "carbon-cache"
      log_template_name "carbon-cache"
      finish_script_template_name "carbon-cache"
      finish true
      options(
        :instance => index,
        :debug => node['graphite']['debug']
      )
    end
    index = index.next
  end

  if node['graphite']['carbon']['relay']['instances'] > 1

    mapped_relay_instances = []
    index = 'a'
    node['graphite']['carbon']['relay']['instances'].times do |i|
      mapped_relay_instances << index
      runit_service "carbon-relay-#{index}" do
        finish true
        template_name "carbon-relay"
        log_template_name "carbon-relay"
        finish_script_template_name "carbon-relay"
        options(
          :instance => "#{index}",
          :debug => node['graphite']['debug']
        )
      end
      index = index.next
    end

  else

    runit_service "carbon-relay" do
      finish true
      options(
        :debug => node['graphite']['debug']
      )
    end

  end

  cleanup_service('carbon-cache')
  cleanup_unmapped_services('carbon-relay-', mapped_relay_instances)
  cleanup_unmapped_services('carbon-cache-', mapped_cache_instances)

else

  runit_service "carbon-cache" do
    finish true
    options(
      :debug => node['graphite']['debug']
    )
  end

  cleanup_service('carbon-relay')
  cleanup_unmapped_services('carbon-relay-')
  cleanup_unmapped_services('carbon-cache-')

end

if node['graphite']['ha_relay']['enable']

  if node['graphite']['ha_relay']['instances'] > 1

    mapped_ha_relay_instances = []
    index = 'a'
    node['graphite']['ha_relay']['instances'].times do |i|
      mapped_ha_relay_instances << index
      runit_service "carbon-relay-ha-#{index}" do
        finish true
        template_name "carbon-relay"
        log_template_name "carbon-relay"
        finish_script_template_name "carbon-relay"
        options(
          :instance => "ha-#{index}",
          :debug => node['graphite']['debug']
        )
      end
      index = index.next
    end

    cleanup_service('carbon-relay-ha')
    cleanup_unmapped_services('carbon-relay-ha-', mapped_ha_relay_instances)

  else

    runit_service "carbon-relay-ha" do
      finish true
      template_name "carbon-relay"
      log_template_name "carbon-relay"
      finish_script_template_name "carbon-relay"
      options(
        :instance => 'ha',
        :debug => node['graphite']['debug']
      )
    end

    cleanup_unmapped_services('carbon-relay-ha-')

  end

end
