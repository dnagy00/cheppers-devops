#
# Cookbook Name:: lamp-drupal
# Recipe:: php
#
# Copyright 2015, Daniel Nagy
#
# All rights reserved - Do Not Redistribute
#

# Base php package
package "php5" do
  action :install
end

# Php pear
package "php-pear" do
  action :install
end

# Other php modules
%w{ php php::module_mysql php::module_gd php::module_curl}.each do |recipe|
    include_recipe recipe
end

# Apply the php ini and restart apache
cookbook_file "/etc/php5/apache2/php.ini" do
  source "php.ini"
  mode "0644"
  notifies :restart, "service[apache2]"
end

execute "chownlog" do
  command "chown www-data /var/log/php"
  action :nothing
end

directory "/var/log/php" do
  action :create
  notifies :run, "execute[chownlog]"
end