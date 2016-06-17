module SdrToolkit
  class PostgisEvent < SdrToolkit::SdrEvent
    require 'pg'

    def initialize
      @connection = PG::Connection.open(
          :dbname => ENV['POSTGIS_DB'],
          :user => ENV['POSTGIS_USER'],
          :password => ENV['POSTGIS_PASS'],
          :host => ENV['POSTGIS_HOST']
      )
    end

    def list_tables
      tables = []
      response = @connection.exec_params("SELECT * FROM information_schema.tables WHERE table_schema = 'public';")
      response.each do |table|
        tables << table["table_name"] unless !table["table_name"].include? 'nyu_2451'
      end
      tables
    end

    def compute_bbox(layer_id)
      begin
        response = @connection.exec_params("SELECT ST_Extent(geom) as table_extent FROM #{layer_id};")
      rescue PG::UndefinedTable => e
        response = []
        puts e.message
      end
      hash = {}
      if response[0] && response[0]['table_extent']
        array = response[0]['table_extent'].gsub('BOX(','').gsub(')','').gsub(',',' ').split(' ')
        hash = {
            :min_x => array[0],
            :max_x => array[2],
            :min_y => array[1],
            :max_y => array[3],
        }
      end
      hash
    end

    def close_connection
      @connection.close
    end

  end
end
