#
# Cookbook Name:: chef_classroom
# Recipe:: deploy_workstations
#
# Author:: Ned Harris (<nharris@chef.io>)
# Author:: George Miranda (<gmiranda@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'chef/provisioning/aws_driver'
with_driver "aws::#{region}"
name = node['chef_classroom']['class_name']

# we need this data_bag during compile
chef_data_bag 'class_machines' do
  action :nothing
end.run_action(:create)

# setup base aws dependencies
include_recipe 'chef_portal::_refresh_iam_creds'
include_recipe 'chef_classroom::_setup_portal_key'
include_recipe 'chef_classroom::_setup_security_groups'

machine_batch do
  1.upto(count) do |i|
    machine "#{name}-workstation-#{i}" do
      machine_options create_machine_options(region, 'amzn', workstation_size, portal_key, 'nodes')
      tag 'workstation'
      recipe 'chef_workstation::full_stack'
      attribute 'guacamole_user', 'chef'
      attribute 'guacamole_pass', 'chef'
    end
  end
end

include_recipe 'chef_classroom::_refresh_portal'
