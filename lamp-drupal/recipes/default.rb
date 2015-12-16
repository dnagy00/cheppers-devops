#
# Cookbook Name:: lamp-drupal
# Recipe:: default
#
# Copyright 2015, Daniel Nagy
#
# All rights reserved - Do Not Redistribute
#

# Basic update on the system
#execute "update-upgrade" do
#  command "apt-get update && apt-get upgrade -y"
#  action :run
#end

#%w{ apt build-essential git curl vim }.each do |recipe|
#  include_recipe recipe
#end

include_recipe "lamp-drupal::apache"
include_recipe "lamp-drupal::mysql"
include_recipe "lamp-drupal::php"
include_recipe "lamp-drupal::drupal"