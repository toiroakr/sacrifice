require 'thor'
require 'sacrifice/utils'
require 'sacrifice/user'
require 'sacrifice/db'

class Users < Thor
  include Utils

  check_unknown_options!

  def self.exit_on_failure?()
    true
  end

  desc 'list', 'List available test users for an application'
  method_option 'app', :aliases => %w[-a], :type => :string, :required => true, :banner => 'Name of the app'

  def list
    app = find_app!(options[:app])
    if app.users.any?
      shell.print_table([
                            ['User ID', 'Access Token', 'Login URL'],
                            *(app.users.map do |user|
                              [user.id, user.access_token, user.login_url]
                            end)
                        ])
    else
      puts "App #{app.name} has no users."
    end
  end

  desc 'create', 'Create a new test user'
  method_option 'app', :aliases => %w[-a], :type => :string, :required => true,
                :banner => 'Name of the app'
  method_option 'name', :aliases => %w[-n], :type => :string, :required => false,
                :banner => 'Name of the new user'
  method_option 'installed', :aliases => %w[-i], :type => :string, :required => false,
                :banner => 'whether your app should be installed for the test user'
  method_option 'locale', :aliases => %w[-l], :type => :string, :required => false,
                :banner => 'the locale for the test user'

  def create
    app = find_app!(options[:app])
    attrs = options.select { |k, v| %w(name installed locale).include? k.to_s }
    user = handle_bad_request do
      app.create_user(attrs)
    end
    if user
      puts "User ID:      #{user.id}"
      puts "Access Token: #{user.access_token}"
      puts "Login URL:    #{user.login_url}"
      puts "Email:        #{user.email}"
      puts "Password:     #{user.password}"
    end
  end

  desc 'friend', 'Make two of an app\'s users friends'
  method_option 'app', :aliases => %w[-a], :type => :string, :required => true, :banner => 'Name of the app'
  method_option 'user1', :aliases => %w[-1 -u1], :type => :string, :required => true, :banner => 'First user ID'
  method_option 'user2', :aliases => %w[-2 -u2], :type => :string, :required => true, :banner => 'Second user ID'

  def friend
    app = find_app!(options[:app])
    users = app.users
    u1 = users.find { |u| u.id.to_s == options[:user1] } or \
          raise Thor::Error, "No user found w/id #{options[:user1].inspect}"
    u2 = users.find { |u| u.id.to_s == options[:user2] } or \
          raise Thor::Error, "No user found w/id #{options[:user2].inspect}"

    # The first request is just a request; the second request
    # accepts the first request.
    handle_bad_request do
      u1.send_friend_request_to(u2)
      u2.send_friend_request_to(u1)
    end
  end

  desc 'change', 'Change a test user\'s name and/or password'
  method_option 'app', :aliases => %w[-a], :type => :string, :required => true,
                :banner => 'Name of the app'
  method_option 'user', :aliases => %w[-u], :type => :string, :required => true,
                :banner => 'ID of the user to change'
  method_option 'name', :aliases => %w[-n], :type => :string, :required => false,
                :banner => 'New name for the user'
  method_option 'password', :aliases => %w[-p], :type => :string, :required => false,
                :banner => 'New password for the user'

  def change
    app = find_app!(options[:app])
    user = app.users.find do |user|
      user.id.to_s == options[:user].to_s
    end

    puts user

    if user
      response = handle_bad_request do
        user.change(options)
      end
      puts response
      if response == 'true'
        puts 'Successfully changed user'
      else
        puts 'Failed to change user'
      end
    else
      raise Thor::Error, "Unknown user '#{options[:user]}'"
    end
  end

  desc 'rm', 'Remove a test user from an application'
  method_option 'app', :aliases => %w[-a], :type => :string, :required => true, :banner => 'Name of the app'
  method_option 'user', :banner => 'ID of the user to remove', :aliases => %w[-u], :type => :string, :required => true

  def rm
    app = find_app!(options[:app])
    user = app.users.find do |user|
      user.id.to_s == options[:user].to_s
    end

    if user
      result = handle_bad_request(raise_error=false) do
        user.destroy
      end
      if result
        puts "User ID #{user.id} removed"
      else
        if @message.match /(\(#2903\) Cannot delete this test account because it is associated with other applications.)/
          error = <<-EOMSG.unindent.gsub(/^\|/, '')
#$1
              Run:
              |
                sacrifice users list-apps --app #{options[:app]} --user #{user.id}
              |
              then for each of the other apps, run:
              |
                sacrifice apps rm-user --app APP-NAME --user #{user.id}
              |
              Then re-run this command.
          EOMSG
        else
          error = @message
        end
        raise Thor::Error, error
      end
    else
      raise Thor::Error, "Unknown user '#{options[:user]}'"
    end
  end

  desc 'destroy', 'Remove all test users from an application. Use with care.'
  method_option 'app', :aliases => %w[-a], :type => :string, :required => true, :banner => 'Name of the app'

  def destroy
    app = find_app!(options[:app])
    app.users.each(&:destroy)
  end

  desc 'generate', 'Generate facebook test users'
  method_option 'app', aliases: %w[-a], type: :string, banner: 'app name that test user generate on' #, required: true
  # method_option 'type', aliases: %w[-t], required: true, type: :string, enum: ['csv'], banner: 'generate type'
  # method_option 'num', aliases: %w[-n], type: :string, banner: 'number of generate test users'
  method_option 'file', aliases: %w[-f], type: :string, banner: 'csv file to read (required in type csv)', required: true
  # method_option 'pattern', aliases: %w[-p], type: :string,
  #               banner: 'Pattern of user name (required in type pattern) : ex. \'Test {} User\' creates test users [\'Test a User\'\, .. \'Test z User\', \'Test A User\'\, .. \'Test Z User\', \'Test aa User\'\, ..]'

  def generate
    # case options[:type].to_sym
    #   when :csv then
    #     if options[:file].nil?
    #       raise Thor::Error, 'option --file is required in type \'csv\''
    #     end
    Csv.generate options[:app], options[:file]
    # when :pattern then
    # else
    #   raise Thor::Error, "undefind type '#{options[:type]}'"
    # end
  end

  desc 'erase', 'Erase facebook test users'
  method_option 'app', aliases: %w[-a], type: :string, banner: 'app name that test user erase on' #, required: true
  # method_option 'type', aliases: %w[-t], required: true, type: :string, enum: ['csv'], banner: 'erase type'
  # method_option 'num', aliases: %w[-n], type: :string, banner: 'number of generate test users'
  method_option 'file', aliases: %w[-f], type: :string, banner: 'file generated by command \'generate\' (required in type csv)', required: true
  # method_option 'pattern', aliases: %w[-p], type: :string,
  #               banner: 'Pattern of user name (required in type pattern) : ex. \'Test {} User\' creates test users [\'Test a User\'\, .. \'Test z User\', \'Test A User\'\, .. \'Test Z User\', \'Test aa User\'\, ..]'

  def erase
    # case options[:type].to_sym
    #   when :csv then
    # if options[:file].nil?
    #   raise Thor::Error, 'option --file is required in type \'csv\''
    # end
    Csv.erase options[:app], options[:file]
    # when :pattern then
    # else
    #   raise Thor::Error, "undefind type '#{options[:type]}'"
    # end
  end
end # Users