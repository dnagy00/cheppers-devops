#
# Cookbook Name:: lamp-drupal
# Recipe:: drupal
#
# Copyright 2015, Daniel Nagy
#
# All rights reserved - Do Not Redistribute
#

# Include recipes for drush
include_recipe 'composer::install'
include_recipe 'activelamp_drupal::drush'

# Start downloading drupal
execute 'drupal-download' do
	cwd "/var/www/"
	command "sudo drush dl drupal-7.x --drupal-project-rename=#{node['lamp-drupal']['sites']['demosite']['name']} -y"
end

sitepath = "/var/www/#{node['lamp-drupal']['sites']['demosite']['name']}"

# Create logs path AGAIN because drush clears the directory
directory "#{sitepath}/logs" do
    action :create
end

# Set the permissions for the downloaded files
directory sitepath do
  mode 0775
  recursive true
end

# Wait for the notification
service "apache2" do
  action :nothing
end

# Install drupal and notify apache2
execute 'drupal-deploy' do
	cwd sitepath
	command "sudo drush si --account-name='#{node['lamp-drupal']['drupal']['admin_user']}' --account-pass='#{node['lamp-drupal']['drupal']['admin_password']}' --db-url='mysql://#{node['lamp-drupal']['mysql']['rds']['user']}:#{node['lamp-drupal']['mysql']['rds']['password']}@#{node['lamp-drupal']['mysql']['rds']['host']}:3306/#{node['lamp-drupal']['mysql']['rds']['db']}' -y"
	notifies :restart, 'service[apache2]'
end