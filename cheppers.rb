#!/usr/bin/env ruby

require 'colorize'
require 'fog/aws'
require 'json'
require 'thor'
require 'highline/import'
require 'net/http'
require 'metainspector'

class Cheppers < Thor

  desc 'create', 'Create a new instance'
  option :credentials, aliases: '-c', default: 'secrets.json', type: :string, desc: 'Credentials file ex: secrets.json'
  option :region, aliases: '-r', default: 'eu-west-1', type: :string, desc: 'Region ex: eu-west-1'
  option :ssh_key, aliases: '-s', default: 'knife', type: :string, desc: 'SSH Key name ex: knife'
  option :zone, aliases: '-z', default: 'eu-west-1b', type: :string, desc: 'Availability Zone'
  option :ami, aliases: '-i', default: 'ami-47a23a30', type: :string, desc: 'Ami image ID ex: ami-47a23a30'
  option :group, aliases: '-g', default: 'cheppers-doc-main', type: :string, desc: 'Security Group ID'
  option :type, aliases: '-t', default: 't2.micro', type: :string, desc: 'Instance Type'
  option :name, aliases: '-n', default: 'Intance name', type: :string, desc: 'Instance Name tag'
  option :timeout, default: 600, type: :numeric, desc: 'Connection timeout'
  option :tags, default: [], type: :array, desc: 'Tags of the instance'
  option :yes, aliases: '-y', default: false, type: :boolean, desc: 'Go through all the confirmations'
  def create
    msg('Creating new instance...')
    puts("\n")
    print_array(options)

    unless get(:yes)
      confirm = ask "Do you really want to launch a new instance with these options? 'yes' or 'no'"
    else
      confirm = 'yes'
    end

    if confirm && confirm == 'yes'

      @server = connection.servers.create(create_server_defs)

      hashed_tags = {}
      tags = get(:tags)
      tags.map { |t| key, val = t.split('='); hashed_tags[key] = val } unless tags.nil?

      # Always set the Name tag
      unless hashed_tags.keys.include? 'Name'
        hashed_tags['Name'] = get(:name) || @server.id
      end

      printed_tags = hashed_tags.map { |tag, val| "#{tag}: #{val}" }.join(', ')

      msg_pair('Instance ID', @server.id)
      msg_pair('Flavor', @server.flavor_id)
      msg_pair('Image', @server.image_id)
      msg_pair('Region', connection.instance_variable_get(:@region))
      msg_pair('Availability Zone', @server.availability_zone)

      printed_security_groups = 'default'
      printed_security_groups = @server.groups.join(', ') if @server.groups
      msg_pair('Security Groups', printed_security_groups) unless @server.groups.nil? && @server.security_group_ids

      msg_pair('Tags', printed_tags)

      msg('Waiting for the instance to be ready', :magenta)

      @server.wait_for(get(:timeout)) { print '.'; ready? }

      puts("\n")

      tries = 6
      begin
        create_tags(hashed_tags) unless hashed_tags.empty?
      rescue Fog::Compute::AWS::NotFound, Fog::Errors::Error
        raise if (tries -= 1) <= 0
        msg("Instance not ready, retrying tag application (retries left: #{tries})", :red)
        sleep 5
        retry
      end

      msg_pair('Public DNS Name', @server.dns_name)
      msg_pair('Public IP Address', @server.public_ip_address)
      msg_pair('Private DNS Name', @server.private_dns_name)
      msg_pair('Private IP Address', @server.private_ip_address)

      puts("\n")

      msg('Your instance is ready to use!', :magenta)

      unless get(:yes)
        confirm = ask "Do you want to use Chef to install Lamp stack and Drupal to this new instance? 'yes' or 'no'"
      else
        confirm = 'yes'
      end

      if confirm && confirm == 'yes'
        install(nil, @server)
      end

    else
      msg('Aborted!', :red)
      exit
    end
  end

  desc 'install ID', 'Install Lamp stack and Drupal to instance'
  option :credentials, aliases: '-c', default: 'secrets.json', type: :string, desc: 'Credentials file ex: secrets.json'
  option :region, aliases: '-r', default: 'eu-west-1', type: :string, desc: 'Region ex: eu-west-1'
  option :yes, aliases: '-y', default: false, type: :boolean, desc: 'Go through all the confirmations'
  def install(id, server=false)

    unless id.nil?
      msg("Install Lamp stack and Drupal to instance... #{id}")
    end

    begin
      if !server
        server = connection.servers.get(id)
      end

      puts("\n")

      msg('Waiting for ssh access to become available', :magenta)

      ssh_connect_host = server.send("public_ip_address")
      msg_pair("SSH Address", "#{ssh_connect_host}")

      wait_for_ssh(ssh_connect_host)

      system build_command(server.public_ip_address)

      if $?
        check(server.public_ip_address)
      else
        msg("The installation routine failed!", :red)
      end
    rescue Fog::Compute::AWS::Error
      msg("Invalid instance ID: #{id}", :red)
    end

  end

  desc 'delete ID', 'Delete an instance with ID'
  option :credentials, aliases: '-c', default: 'secrets.json', type: :string, desc: 'Credentials file ex: secrets.json'
  option :region, aliases: '-r', default: 'eu-west-1', type: :string, desc: 'Region ex: eu-west-1'
  option :yes, aliases: '-y', default: false, type: :boolean, desc: 'Go through all the confirmations'
  # option :id, :aliases => '-i', :required => true, :type => :string, :desc => 'Instance ID ex: i-4ca2b7f5'
  def delete(id)
    # instance_id = get(:id)

    msg("Deleting instance... #{id}")

    begin
      @server = connection.servers.get(id)

      puts("\n")

      msg_pair('Instance ID', @server.id)
      msg_pair('Instance Name', @server.tags['Name'])
      msg_pair('Flavor', @server.flavor_id)
      msg_pair('Image', @server.image_id)
      msg_pair('Region', connection.instance_variable_get(:@region))
      msg_pair('Availability Zone', @server.availability_zone)
      msg_pair('Security Groups', @server.groups.join(', '))
      msg_pair('SSH Key', @server.key_name)
      msg_pair('Root Device Type', @server.root_device_type)
      msg_pair('Public DNS Name', @server.dns_name)
      msg_pair('Public IP Address', @server.public_ip_address)
      msg_pair('Private DNS Name', @server.private_dns_name)
      msg_pair('Private IP Address', @server.private_ip_address)

      puts("\n")

      unless get(:yes)
        confirm = ask "Do you really want to delete this instance? 'yes' or 'no'"
      else
        confirm = 'yes'
      end

      if confirm && confirm == 'yes'
        @server.destroy

        msg("Instance has been successfully deleted: #{@server.id}", :magenta)
      else

        msg('Aborted!', :red)
        exit

      end

    rescue Fog::Compute::AWS::Error
      msg("Invalid instance ID: #{id}", :red)
    end
  end

  desc 'stop ID', 'Stop an instance with ID'
  option :credentials, aliases: '-c', default: 'secrets.json', type: :string, desc: 'Credentials file ex: secrets.json'
  option :region, aliases: '-r', default: 'eu-west-1', type: :string, desc: 'Region ex: eu-west-1'
  option :yes, aliases: '-y', default: false, type: :boolean, desc: 'Go through all the confirmations'
  # option :id, :aliases => '-i', :required => true, :type => :string, :desc => 'Instance ID ex: i-4ca2b7f5'
  def stop(id)
    # instance_id = get(:id)

    msg("Stopping instance... #{id}")

    begin

      @server = connection.servers.get(id)

      if !@server && @server.nil?
        msg("Invalid instance ID: #{id}", :red)
        exit
      end

      puts("\n")

      msg_pair('Instance ID', @server.id)
      msg_pair('Instance Name', @server.tags['Name'])
      msg_pair('Flavor', @server.flavor_id)
      msg_pair('Image', @server.image_id)
      msg_pair('Region', connection.instance_variable_get(:@region))
      msg_pair('Availability Zone', @server.availability_zone)
      msg_pair('Security Groups', @server.groups.join(', '))
      msg_pair('SSH Key', @server.key_name)
      msg_pair('Root Device Type', @server.root_device_type)
      msg_pair('Public DNS Name', @server.dns_name)
      msg_pair('Public IP Address', @server.public_ip_address)
      msg_pair('Private DNS Name', @server.private_dns_name)
      msg_pair('Private IP Address', @server.private_ip_address)

      puts("\n")

      unless get(:yes)
        confirm = ask "Do you really want to stop this instance? 'yes' or 'no'"
      else
        confirm = 'yes'
      end

      if confirm && confirm == 'yes'
        @server.stop

        msg("Instance has been successfully stopped: #{@server.id}", :magenta)
      else

        msg('Aborted!', :red)
        exit

      end

    rescue Fog::Compute::AWS::Error
      msg("Invalid instance ID: #{id}", :red)
    end
  end

  desc 'check URL', 'Check if drupal is installed correctly'
  def check(url)
    msg("Checking drupal install on: #{url}")

    page = MetaInspector.new("#{url}/install.php")

    if page.response.status == 200
      if page.title == 'Drupal already installed | Drupal'
        msg("Website #{url} is online and Drupal has been installed successfully", :green)
      else
        msg("Website #{url} is online but Drupal has not been installed yet", :red)
      end
    else
      msg("Website returned with status code: #{http.code}", :cyan)
    end
  rescue NameError
    msg("Website #{url} is offline or Drupal has not been installed yet", :red)
  rescue Faraday::ConnectionFailed
    msg("Website #{url} is offline")
  end

  # MISC #

  no_commands do
    def connection
      credentials = JSON.load(File.read(get(:credentials)))
      # Aws::Credentials.new( credentials['AccessKeyId'], credentials['SecretAccessKey'] )

      connection_settings = {
        provider: 'AWS',
        region: get(:region),
        aws_access_key_id: credentials['AccessKeyId'],
        aws_secret_access_key: credentials['SecretAccessKey']
      }

      @connection ||= begin
        puts 'Connecting...'
        connection = Fog::Compute.new(connection_settings)
        # connection = Aws::EC2::Client.new( connection_settings )
      end
    end

    def create_server_defs
      server_def = {
        image_id: get(:ami),
        # :groups => config[:security_groups],
        security_group_ids: get(:group),
        flavor_id: get(:type),
        key_name: get(:ssh_key),
        availability_zone: get(:zone)
      }

      server_def
    end

    def create_tags(hashed_tags)
      hashed_tags.each_pair do |key, val|
        connection.tags.create key: key, value: val, resource_id: @server.id
      end
    end

    def wait_for_ssh(host)
      initial = true
        print '.' until test_ssh(host, 22) {
          if initial
            initial = false
            sleep 10
          else
            sleep 10
          end
          puts("\nConnected...")
        }
    end

    def build_command(ip)
      ssh_key = get(:ssh_key)

      if ssh_key.nil?
       ssh_key = 'knife'
     end

      command = "knife bootstrap #{ip} -r 'role[base],role[lampdrupal]' -i /home/ubuntu/chef-repo/.chef/#{ssh_key}.pem --ssh-user ubuntu --sudo"
      command
    end

    def test_ssh(hostname, ssh_port)
      tcp_socket = TCPSocket.new(hostname, ssh_port)
      readable = IO.select([tcp_socket], nil, nil, 5)
      if readable
        ssh_banner = tcp_socket.gets
        if ssh_banner.nil? || ssh_banner.empty?
          false
        else
          yield
          true
        end
      else
        false
      end
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ENOTCONN, IOError
      print '.'
      sleep 2
      false
    rescue Errno::EPERM, Errno::ETIMEDOUT
      print '.'
      false
    rescue Errno::ECONNRESET
      print '.'
      sleep 2
      false
    ensure
      tcp_socket && tcp_socket.close
    end

    def get(key)
      options[key] || nil
    end

    def set(key, value)
      options[key] = value
    end

    def print_array(array)
      array.each_pair do |key, val|
        msg_pair(key.split('_').map(&:capitalize).join("\s"), val, :cyan)
      end
    end

    def msg_pair(label, value, color = :red)
      if value && !value.to_s.empty?
        puts "#{label}".colorize(color) + ": #{value}"
      end
    end

    def msg(value, color = :magenta)
      puts "#{value}".colorize(color)
    end
  end
end

Cheppers.start(ARGV)
