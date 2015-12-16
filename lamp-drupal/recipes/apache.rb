#
# Cookbook Name:: lamp-drupal
# Recipe:: apache
#
# Copyright 2015, Daniel Nagy
#
# All rights reserved - Do Not Redistribute
#

# Install apache

package "apache2" do
  action :install
end

# Enable and Start Apache
service "apache2" do
  action [:enable, :start]
end

# Install other modules for apache
include_recipe 'apache2::mod_rewrite'
include_recipe 'apache2::mod_php5'

# Variables
sitename = node["lamp-drupal"]["sites"]["demosite"]["name"]
sitepath = "/var/www/#{sitename}"

# Create directory
directory sitepath do
    action :create
end

# Create logs directory
directory "#{sitepath}/logs" do
  action :create
end

# Set chmod recursively
directory "/var/www/" do
  mode 0755
  recursive true
end

# Enables virtualhost updates
execute "enable-sites" do
  command "a2ensite #{sitename}"
  action :nothing
end

# Create virtualhost file
template "/etc/apache2/sites-available/#{sitename}.conf" do
	source "virtualhost.erb"
	mode "0644"
	variables(
    :sitepath => sitepath,
    :port => node["lamp-drupal"]["sites"]["demosite"]["port"],
    :serveradmin => node["lamp-drupal"]["sites"]["demosite"]["serveradmin"],
    :servername => node["lamp-drupal"]["sites"]["demosite"]["servername"],
    :sitename => sitename
  )
  notifies :run, "execute[enable-sites]"
  notifies :restart, "service[apache2]"
end

