require 'rest-client'
module Utils
  def find_app!(name)
    app = App.find_by_name(name)
    unless app
      raise Thor::Error, "Unknown app #{name}. Run 'fbtu apps' to see known apps."
    end
    app
  end

  def bad_request_message(bad_request)
    response = bad_request.response
    json = JSON.parse(response)
    json['error']['message'] rescue json.inspect
  end

  def handle_bad_request(raise_error=true)
    begin
      yield
    rescue RestClient::BadRequest => bad_request
      @message = bad_request_message(bad_request)
      raise Thor::Error, "#{bad_request.class}: #@message" if raise_error
      nil
    end
  end
end
