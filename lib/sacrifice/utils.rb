require 'rest-client'

module Utils
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
