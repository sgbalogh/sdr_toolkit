module SdrToolkit
  class FdaRestEvent < SdrToolkit::SdrEvent
    require 'rest-client'
    require 'json'

    attr_accessor :token

    def initialize
      super()
      @client = RestClient::Request
    end

    def standard_params
      {

      }
    end

    def authenticate
      parameters = {
          :url => ENV['FDA_REST_URL'] + '/login',
          :method => :post,
          :verify_ssl => false,
          :payload => {
              :email => ENV['FDA_REST_USER'],
              :password => ENV['FDA_REST_PASS']
          }.to_json,
          :headers => {
              'Content-Type' => 'application/json'
          }
      }
      self.token = @client.execute(parameters)
    end


  end
end
