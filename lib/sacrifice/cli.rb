require 'sacrifice'
require 'thor'
require 'facebook_test_users'

module Sacrifice
  class CLI < Thor
    desc 'test', 'test'
    def shout word, color = 'red'
      say(word, color.to_sym)
    end
  end
end