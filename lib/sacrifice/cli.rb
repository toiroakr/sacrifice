require 'sacrifice'
require 'thor'
require 'sacrifice/csv'
require 'sacrifice/apps'
require 'sacrifice/users'

module Sacrifice
  class CLI < Thor
    desc 'apps', 'Commands for managing Facebook applications'
    subcommand :apps, Apps

    desc 'users', 'Commands for managing Facebook applications test users'
    subcommand :users, Users
  end
end