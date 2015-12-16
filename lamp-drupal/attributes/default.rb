
default["lamp-drupal"]["sites"]["demosite"] = { "name" => "demosite", "port" => 80, "servername" => "example.com", "serveradmin" => "webmaster@demosite.com" }


default['apache']['docroot_dir'] = '/var/www/demosite'

include_attribute 'lamp-drupal::mysql'
include_attribute 'lamp-drupal::drupal'