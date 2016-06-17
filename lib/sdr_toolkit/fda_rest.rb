module SdrToolkit
  class FdaRestEvent < SdrToolkit::SdrEvent
    require 'rest-client'
    require 'json'

    attr_accessor :token

    def initialize
      super()
      @client = RestClient::Request
      @token
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

    def logout
      parameters = {
          :url => ENV['FDA_REST_URL'] + '/logout',
          :method => :post,
          :verify_ssl => false,
          :headers => {
              'Content-Type' => 'application/json',
              'rest-dspace-token' => @token
          }
      }
      self.token = @client.execute(parameters)
    end

    def delete_item(item_id)
      authenticate
      parameters = {
          :url => ENV['FDA_REST_URL'] + '/items/' + item_id.to_s,
          :method => :delete,
          :verify_ssl => false,
          :headers => {
              'Content-type' => 'application/json',
              'Accept' => 'application/json',
              'rest-dspace-token' => @token,
          }
      }
      @client.execute(parameters)
    end

    def create_container(collection_id)
      authenticate
      parameters = {
          :url => ENV['FDA_REST_URL'] + '/collections/' + collection_id.to_s + '/items',
          :method => :post,
          :verify_ssl => false,
          :payload => {
              :metadata =>[
                  {
                      :key=>"dc.title",
                      :language=>"en_US",
                      :value=>"Empty Container Document"}
              ]
          }.to_json,
          :headers => {
              'Content-type' => 'application/json',
              'Accept' => 'application/json',
              'rest-dspace-token' => @token
          }
      }
      JSON.parse(@client.execute(parameters))
    end

    def add_bitstream(item_id, path_to_bitstream)
      authenticate
      upload = File.new(path_to_bitstream)
      parameters = {
          :url => ENV['FDA_REST_URL'] + '/items/' + item_id.to_s + '/bitstreams',
          :method => :post,
          :verify_ssl => false,
          :payload => {
              :content => upload
          },
          :headers => {
              'Content-type' => 'application/json',
              'Accept' => 'application/json',
              'rest-dspace-token' => @token,
              :params => {
                  :name => File.basename(path_to_bitstream),
              }
          }
      }
      JSON.parse(@client.execute(parameters))
    end

    def alter_item_metadata(item_id, metadata_array)
      authenticate
      parameters = {
          :url => ENV['FDA_REST_URL'] + '/items/' + item_id.to_s + '/metadata',
          :method => :put,
          :verify_ssl => false,
          :payload => metadata_array.to_json,
          :headers => {
              'Content-type' => 'application/json',
              'Accept' => 'application/json',
              'rest-dspace-token' => @token,
          }
      }
      @client.execute(parameters)

    end

    def get_collection_metadata(collection_id)
      authenticate
      parameters = {
          :url => ENV['FDA_REST_URL'] + '/collections/' + collection_id.to_s + '/items',
          :method => :get,
          :verify_ssl => false,
          :headers => {
              'Content-type' => 'application/json',
              'Accept' => 'application/json',
              'rest-dspace-token' => @token,
              :params => {
                  :expand => 'metadata,bitstreams,parentCollection',
                  :limit => 1000
              }
          }
      }
      JSON.parse(@client.execute(parameters))
    end
  end
end
