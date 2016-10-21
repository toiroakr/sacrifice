require 'sacrifice/const'
require 'csv'
require 'json'

class Csv
  CREATE_OPTIONS = [:name, :install, :locale]
  CHANGE_OPTIONS = [:password]
  OUTPUT_ORDER = [:id, :name, :email, :password, :login_url, :access_token]

  def self.generate app_name, file, friends_file
    app = App.find! app_name
    output = init_output(app_name, file)

    friends = []
    if friends_file
      CSV.read(friends_file, headers: true, header_converters: :symbol).each { |data|
        friends.push app.find_user(data[:id])
      }
    end

    headers = []
    CSV.read(file, headers: true, header_converters: :symbol).each { |data|
      if headers.empty?
        headers = CSV.read(file).first.map { |header| header.to_sym }
      else
        puts '==================================='
      end

      # set default options
      create_options = {locale: 'ja_JP'}
      change_options = {}

      # read option
      headers.each { |option|
        create_options[option] = data[option] if CREATE_OPTIONS.include? option
        change_options[option] = data[option] if CHANGE_OPTIONS.include? option
      }

      # execute create
      user = nil
      # repeat creating and destroying until user who has target gender created
      begin
        user.destroy if user
        user = app.create_user(create_options)
      end while user.invalid_gender(data[:gender])

      # execute change
      if change_options.any? and user.change(change_options)
        user.password = change_options[:password] if change_options[:password]
      elsif change_options[:password]
        puts "Failed to update password to #{change_options[:password]}"
      end

      # print created user
      user_map = user.attrs
      user_map[:name] = create_options[:name] if create_options[:name]
      puts user_map.map { |key, value| "#{key.upcase} : #{value}" }

      # log created user
      CSV.open(output, 'a') { |line|
        output_line = []
        OUTPUT_ORDER.each { |key|
          output_line.push user_map[key]
        }
        line << output_line
      } unless user.id.nil?

      user = app.find_user(user.id)
      if friends.any?
        friends.each { |friend|
          user.send_friend_request_to(friend)
        }
      end
    }
  end

  def self.erase app_name, file
    users = App.find!(app_name).users

    headers = []
    CSV.read(file, headers: true, header_converters: :symbol).each { |data|
      if headers.empty?
        headers = CSV.read(file).first.map { |header| header.to_sym }
      end
      user = users.find { |user|
        user.id.to_s == data[:id].to_s
      }
      if user
        user.destroy
        puts "remove user ##{user.id}"
      else
        puts "user ##{data[:id]} not found"
      end
    }
  end

  def self.init_output(app_name, file)
    output = "sacrificed_#{app_name}_#{file}"
    File.open(output, 'a').close
    output_file = File.open(output, 'r')
    CSV.open(output, 'a') { |line| line << OUTPUT_ORDER } if output_file.size == 0
    output_file.close
    output
  end
end