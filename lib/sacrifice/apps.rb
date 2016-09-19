require 'thor'
require 'sacrifice/utils'
require 'sacrifice/app'
require 'sacrifice/db'

class Apps < Thor
  include Utils

  check_unknown_options!

  def self.exit_on_failure?()
    true
  end

  default_task :list

  desc 'register', 'Tell fbtu about a new application (must already exist on Facebook)'
  method_option 'app_id', aliases: %w[-i], :type => :string, :required => true, :banner => 'OpenGraph ID of the app'
  method_option 'app_secret', aliases: %w[-s], :type => :string, :required => true, :banner => 'App\'s secret key'
  method_option 'name', aliases: %w[-n], :type => :string, :required => true, :banner => 'Name of the app (so you don\'t have to remember its ID)'

  def register
    App.create!(:name => options[:name], :id => options[:app_id], :secret => options[:app_secret])
    list
  end

  desc 'list', 'List the applications fbtu knows about'
  method_option 'verbose', aliases: %w[-v], :type => :boolean, :banner => 'Show app secret'

  def list
    App.all.each do |app|
      puts "#{app.name} (id: #{app.id}#{", secret: #{app.secret}" if options[:verbose]})"
    end
  end

end # Apps