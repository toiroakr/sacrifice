require 'thor'
require 'sacrifice/csv'
require 'sacrifice/user'

class Users < Thor

  check_unknown_options!

  def self.exit_on_failure?()
    true
  end

  desc 'list', 'List available test users for an application'
  method_option 'app', :aliases => %w[-a], :type => :string, :required => true, :banner => 'Name of the app'

  def list
    app = App.find!(options[:app])
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
    app = App.find!(options[:app])
    attrs = options.select { |k, v| %w(name installed locale).include? k.to_s }
    user = app.create_user(attrs)
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
    users = App.find!(options[:app]).users

    friends = []
    [options[:user1], options[:user2]].each { |user|
      friends.push (users.find { |u| u.id.to_s == user } or raise Thor::Error, "No user found w/id #{user.inspect}")
    }

    # The first request is just a request, the second request accepts the first request.
    friends.each_index { |idx| friends[idx].send_friend_request_to[(idx + 1) % 2] }
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
    user = App.find!(options[:app]).find_user(options[:user])

    puts user

    if user
      success = user.change(options)
      if success
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
    user = App.find!(options[:app]).find_user(options[:user])

    if user
      result = user.destroy
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
    app = App.find!(options[:app])
    while (users = app.users).size > 0
      users.each { |user|
        user.destroy
        puts "remove user ##{user.id}"
      }
    end
  end

  desc 'generate', 'Generate facebook test users'
  method_option 'app', aliases: %w[-a], type: :string, banner: 'app name that test user generate on' #, required: true
  method_option 'file', aliases: %w[-f], type: :string, banner: 'csv file to read (required in type csv)', required: true

  def generate
    Csv.generate options[:app], options[:file]
  end

  desc 'erase', 'Erase facebook test users'
  method_option 'app', aliases: %w[-a], type: :string, banner: 'app name that test user erase on' #, required: true
  method_option 'file', aliases: %w[-f], type: :string, banner: 'file generated by command \'generate\' (required in type csv)', required: true

  def erase
    Csv.erase options[:app], options[:file]
  end
end