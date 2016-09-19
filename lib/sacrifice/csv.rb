require 'sacrifice'
require 'sacrifice/cli'
require 'sacrifice/const'
require 'csv'
require 'open5'
require 'curb'
require 'json'

class Csv
  BASE_COMMAND = 'sacrifice users'
  CREATE_OPTIONS = [:app, :name, :install, :locale]
  CHANGE_OPTIONS = [:app, :password]
  RM_OPTIONS = [:name]
  GENERATED = [
      {type: :id, pattern: %r{Login URL:\s+https://developers.facebook.com/checkpoint/test-user-login/(\w+)/}},
      {type: :access_token, pattern: %r{Access Token:\s+(\w+)}},
      {type: :email, pattern: %r{Email:\s+([\w@¥.]+)}},
      {type: :password, pattern: %r{Password:\s+(\w+)}}
  ]

  def self.generate app, file
    output = 'sacrificed_' + file
    headers = nil
    CSV.read(file, headers: true).each { |data|
      if headers.nil?
        headers = CSV.read(file).first { |header| header.to_sym }
      else
        puts '==================================='
      end

      # set default options
      create_options = {app: app, locale: 'ja_JP'}
      gender_options = {app: app}
      change_options = {}

      # read option
      headers.each { |option|
        create_options[option.to_sym] = data[option] if CREATE_OPTIONS.include? option.to_sym
        gender_options[option.to_sym] = data[option] if :gender == option.to_sym
        change_options[option.to_sym] = data[option] if CHANGE_OPTIONS.include? option.to_sym
      }

      # execute create
      generated = {}
      begin
        generated = {}
        open5(command(:create, *create_options)) { |i, o, e, t|
          o.each { |line|
            GENERATED.each { |item|
              match = line.match item[:pattern]
              if item[:type] == :access_token
                change_options[:access_token] = match[1] unless match.nil?
                gender_options[:access_token] = match[1] unless match.nil?
              else
                generated[item[:type]] = match[1] unless match.nil?
              end
            }
          }
        }
        gender_options[:user] = generated[:id]
      end while need_retry_for_gender(gender_options)
      CSV.open(output, 'a') { |line|
        user = [generated[:id]]
        data.each { |key, value|
          user.push value
        }
        line << user
      } unless generated[:id].nil?

      # execute change
      if change_options.any?
        result = JSON.parse(Curl.post("#{GRAPH_API_BASE}/#{generated[:id]}", change_options).body_str)
        if result['success']
          generated[:password] = change_options[:password]
        else
          puts "Failed to update password to #{change_options[:password]}"
        end
      end
      puts create_options.merge(change_options).merge(generated).map { |key, value|
        "#{key.upcase} : #{value}"
      }
    }
  end

  def self.erase app, file
    headers = nil
    CSV.read(file, headers: true).each { |data|
      if headers.nil?
        headers = CSV.read(file).first { |header| header.to_sym }
      else
        puts '==================================='
      end

      # set default options
      rm_options = {app: app}

      # read option
      headers.each { |option|
        rm_options[option.to_sym] = data[option] if RM_OPTIONS.include? option.to_sym
      }
    }
  end

  private
  def self.need_retry_for_gender gender_options
    if gender_options[:gender].nil?
      return false
    end
    result = JSON.parse(Curl.get("#{GRAPH_API_BASE}/#{gender_options[:user]}?fields=gender", {access_token: gender_options[:access_token]}).body_str)
    puts result
    if result['gender'] == gender_options[:gender]
      return false
    end
    `#{command(:rm, *{app: gender_options[:app], user: gender_options[:user]})}`
    true
  end

  private
  def self.command type, *options
    parts = [BASE_COMMAND, type.to_s]
    options.map { |option, value|
      parts.push "--#{option}"
      parts.push "'#{value}'"
    }
    parts.join ' '
  end
end