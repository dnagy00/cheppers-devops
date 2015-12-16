#
# Cookbook Name:: lamp-drupal
# Recipe:: mysql
#
# Copyright 2015, Daniel Nagy
#
# All rights reserved - Do Not Redistribute
#

# First install mysql2 Ruby gem
mysql2_chef_gem 'mysql-default' do
	action :install
end

# Install the client
mysql_client 'mysql-default' do
	action :create
end

# Install the service
mysql_service "mysql-default" do
  initial_root_password node["lamp-drupal"]["mysql"]["local"]["password"]
  action [:create, :start]
end

# Create database
#mysql_database node["lamp-drupal"]["mysql"]["local"]['db'] do
#  connection( :host => node["lamp-drupal"]["mysql"]["local"]['host'], :username => node["lamp-drupal"]["mysql"]["local"]['user'],:password => node["lamp-drupal"]["mysql"]["local"]['password'] )
#  action :create
#end

# Create user for the database
#mysql_database_user node["lamp-drupal"]["mysql"]["local"]['db'] do
#  connection( :host => node["lamp-drupal"]["mysql"]["local"]['host'], :username => node["lamp-drupal"]["mysql"]["local"]['user'],:password => node["lamp-drupal"]["mysql"]["local"]['password'] )
#  password node["lamp-drupal"]["mysql"]["local"]['password']
#  database_name node["lamp-drupal"]["mysql"]["local"]['db']
#  privileges [:select,:update,:insert,:create,:delete]
#  action :grant
#end