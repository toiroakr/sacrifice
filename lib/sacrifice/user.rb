require 'uri'
require 'sacrifice/utils'
require 'sacrifice/const'

class User
  include Utils

  attr_accessor :id, :access_token, :login_url, :email, :password

  def initialize(attrs)
    attrs.each do |field, value|
      instance_variable_set("@#{field}", value) if respond_to?(field)
    end
  end

  def change(options = {})
    handle_bad_request do
      JSON.parse(RestClient.post("#{GRAPH_API_BASE}/#{id}", {access_token: access_token}.merge(options)))['success']
    end
  end

  def owner_apps(app)
    handle_bad_request do
      RestClient.get("#{GRAPH_API_BASE}/#{id}/ownerapps?access_token=#{URI.escape(app.access_token.to_s)}")
    end
  end

  def destroy
    handle_bad_request(raise_error=false) do
      RestClient.delete("#{GRAPH_API_BASE}/#{id}?access_token=#{URI.escape(access_token.to_s)}")
    end
  end

  # Facebook test users all share the same birthday. Perhaps it's the developer's!
  def birthday
    Date.new(1980, 8, 8)
  end

  def send_friend_request_to(other)
    handle_bad_request do
      RestClient.post("#{GRAPH_API_BASE}/#{id}/friends/#{other.id}", 'access_token' => access_token.to_s)
    end
  end

  def invalid_gender(gender)
    if gender.nil?
      return
    end
    handle_bad_request do
      result = JSON.parse(RestClient.get("#{GRAPH_API_BASE}/#{id}?fields=gender&access_token=#{access_token}").body)
      if result['gender'] == gender
        return
      end
    end
    true
  end

  def attrs
    {id: id, access_token: access_token, login_url: login_url, email: email, password: password}
  end
end
