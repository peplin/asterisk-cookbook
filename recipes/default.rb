#
# Cookbook Name:: asterisk
# Recipe:: default
#
# Copyright 2011, Chris Peplin
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
when "ubuntu","debian"
  bash "add apt key" do
    code "apt-key adv --keyserver subkeys.pgp.net --recv-keys 175E41DF"
    action :nothing
    notifies :run, resources(:bash => "apt-get update"), :immediately
  end

  template "/etc/apt/sources.list.d/asterisk.list" do
    source "asterisk.list.erb"
    mode 0644
    notifies :run, resources(:bash => "add apt key"), :immediately
  end
end

packages = case node[:platform]
when "ubuntu","debian"
  %w{asterisk-1.8 asterisk-dahdi}
when "arch"
  # Install from the AUR
  []
end

packages.each do |pkg|
  package pkg
end

asterisk_service_name = case node[:platform]
when "ubuntu","debian"
  "asterisk-1.8"
when "arch"
  "asterisk"
end

service "asterisk" do
  service_name asterisk_service_name
  supports :restart => true, :reload => true, :status => :true, :debug => :true,
    "logger-reload" => true, "extensions-reload" => true,
    "restart-convenient" => true, "force-reload" => true
end

external_ip = node[:ec2] ? node[:ec2][:public_ipv4] : node[:ipaddress]
users = search(:asterisk)
auth = search(:auth, "id:google")

%w{sip manager modules extensions gtalk jabber}.each do |template_file|
  template "/etc/asterisk/#{template_file}.conf" do
    source "#{template_file}.conf.erb"
    owner "asterisk"
    group "asterisk"
    mode 0644
    variables :external_ip => external_ip, :users => users, :auth => auth[0]
    notifies :reload, resources(:service => "asterisk")
  end
end
