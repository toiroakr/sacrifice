require 'sacrifice'
require 'thor'
require 'facebook_test_users'

module Sacrifice
  class CLI < Thor
    desc 'test'
    def red word
      say(word, :red)
    end
  end
end