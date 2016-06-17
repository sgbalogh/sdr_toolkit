module SdrToolkit
  class Utils
    require 'find'

    ## FDA methods

    def self.find_unmatched_fda_records
      unmatched_fda_ids = []
      unmatched_fda_records = []
      matched_fda_ids = []
      all_fda = Documents::FdaRecord.all
      all_git = Documents::OgmRecord.all
      all_fda.each do |fda_record|
        corresponding_git_id = fda_record.slugify
        if Documents::OgmRecord.find(corresponding_git_id)
          matched_fda_ids << corresponding_git_id
        else
          unmatched_fda_records << fda_record
          unmatched_fda_ids << corresponding_git_id
        end

      end
      puts "Found #{matched_fda_ids.count} matching records (of #{all_git.count} total OGM records).\nCould not find matches for #{unmatched_fda_ids.count} records that are in FDA."
      return unmatched_fda_records
    end

    def self.display_unmatched_fda_records
      records = find_unmatched_fda_records
      records.each do |record|
        not_empty_flag = "*"
        if !record.metadata['bitstreams'] || record.metadata['bitstreams'].count == 0
          not_empty_flag = ""
        end

        puts "#{record.slugify} \t #{record.urlify} \t #{collection_id_to_text(record.metadata['parentCollection']['id'])} \t #{not_empty_flag} #{record.metadata['name']}"
      end
      return nil
    end

    def self.delete_all_unmatched_fda_records

    end

    def self.delete_empty_unmatched_fda_records
      records = find_unmatched_fda_records
      empty = []

      records.each do |record|
        if record.metadata['bitstreams'].count == 0
          empty << record
        end
      end
      event = SdrToolkit::FdaRestEvent.new()
      empty.each do |empty_record|
        event.delete_item(empty_record._id)
        empty_record.delete
      end
      event.logout
    end

    def self.create_containers(collection, quantity)
      event = SdrToolkit::FdaRestEvent.new()
      collection_id = nil

      if collection.downcase == 'restricted'
        collection_id = ENV['SDR_RESTRICTED_FDA_ID']
      elsif collection.downcase == 'public'
        collection_id = ENV['SDR_PUBLIC_FDA_ID']
      end

      new_containers = []
      quantity.times do |create|
        new_containers << event.create_container(collection_id)
      end
      event.logout

      self.update_mongo_fda
      new_containers
    end

    def self.gather_empty_containers
      records = find_unmatched_fda_records
      empty_containers = []
      records.each do |record|
        if record.metadata['bitstreams'] && record.metadata['bitstreams'].count == 0 && record.metadata['name'] == "Empty Container Document"
          empty_containers << record
          puts "#{collection_id_to_text(record.metadata['parentCollection']['id'])} container #{record.slugify} is empty."
        end
      end
      empty_containers
    end

    def self.sync_ogm_metadata_to_fda
      update_db # Forces db update
      all_fda = Documents::FdaRecord.all

      event = SdrToolkit::FdaRestEvent.new()
      all_fda.each do |fda_record|
        corresponding_ogm_record = Documents::OgmRecord.find(fda_record.slugify)
        puts corresponding_ogm_record.metadata['dc_title_s'] unless corresponding_ogm_record.nil?
        unless corresponding_ogm_record.nil?
          altered_metadata = [
              {
                  'key' => "dc.title",
                  'language' => "en_US",
                  'value' => corresponding_ogm_record.metadata['dc_title_s']
              }
          ]
          event.alter_item_metadata(fda_record.id, altered_metadata) unless fda_record.metadata['metadata'].include? altered_metadata[0]
        end
      end
      event.logout
    end

    def self.upload_bitstreams_to_fda
      event = SdrToolkit::FdaRestEvent.new()

      bitstream_upload_paths = []
      Find.find('tmp/bitstream_uploads') do |path|
        bitstream_upload_paths << path if path =~ /.*\d\d\d\.(zip)$/i || path =~ /.*wgs84\.(zip)$/i || path =~ /.*doc\.(zip)$/i
      end

      bitstream_upload_paths.each do |path|
        filename = File.basename(path)
        record_slug = File.basename(filename, ".*").gsub('_doc', '').gsub('_WGS84', '')
        fda_record = find_fda_record_from_ogm_slug(record_slug)
        puts "About to check #{record_slug} and filename #{filename}"
        unless check_if_bitstream_exists(record_slug, filename)
          bitstream = event.add_bitstream(fda_record.id, path)
          fda_record.metadata['bitstreams'] << bitstream
          fda_record.update
        end
      end

      return bitstream_upload_paths

      event.logout
    end

    # For bitstream name, do not include extension
    def self.check_if_bitstream_exists(record_slug, bitstream_name)
      bitstreams = return_bitstreams_for_record(record_slug)
      bitstreams.each do |bitstream|
        if bitstream['name']
          if File.basename(bitstream['name'], ".*") == File.basename(bitstream_name, ".*")
            return true
          end
        end
      end
      return false
    end

    def self.return_bitstreams_for_record(record_slug)
      record = find_fda_record_from_ogm_slug(record_slug)
      record.metadata['bitstreams']

    end

    def self.find_fda_record_from_ogm_slug(record_slug)
      records = Documents::FdaRecord.where('metadata.handle' => record_slug.gsub('nyu_', '').gsub('_', '/'))
      records[0]
    end

    def self.collection_id_to_text(collection_id)
      if collection_id.to_s == ENV['SDR_PUBLIC_FDA_ID']
        return 'Public'
      elsif collection_id.to_s == ENV['SDR_RESTRICTED_FDA_ID']
        return 'Restricted'
      end
    end

    ## PostGIS methods

    def self.recompute_vector_bounding_boxes
      Documents::BboxCoordinates.delete_all

      event = SdrToolkit::PostgisEvent.new
      layers = event.list_tables
      layers.each do |layer|
        bbox_hash = event.compute_bbox(layer)
        bbox_hash[:_id] = layer
        bbox_hash[:last_updated] = Time.now
        unless bbox_hash.nil?
          new_rec = Documents::BboxCoordinates.new(bbox_hash)
          new_rec.upsert
        end
      end
      event.close_connection
    end

    def self.compute_missing_vector_bounding_boxes
      event = SdrToolkit::PostgisEvent.new
      layers = event.list_tables
      total_count = layers.count
      increment = 1
      layers.each do |layer|
        if Documents::BboxCoordinates.find(layer).nil?
          bbox_hash = event.compute_bbox(layer)
          bbox_hash[:_id] = layer
          bbox_hash[:last_updated] = Time.now
          unless bbox_hash.nil?
            new_rec = Documents::BboxCoordinates.new(bbox_hash)
            new_rec.upsert
          end
        end
        puts "#{increment.to_s} out of #{total_count} layers completed"
        increment += 1
      end
      event.close_connection
    end

    ## OGM Record methods

    def self.create_space_for_json_export
      unless File.directory?('tmp/exports/ogm')
        FileUtils.mkdir_p('tmp/exports/ogm')
      end
      directory_name = "tmp/exports/ogm/#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}"
      FileUtils.mkdir_p(directory_name)

      directory_name
    end

    def self.create_json_records_from_db
      export_directory = create_space_for_json_export
      ogm_records = Documents::OgmRecord.all
      ogm_records.each do |record|
        FileUtils.mkdir_p(export_directory + '/' + record.relative_path)
        File.open(export_directory + '/' + record.relative_path + '/geoblacklight.json', 'w') do |f|
          f.write(JSON.pretty_generate(record.metadata))
        end
      end
    end

    def self.create_records_w_updated_bbox
      export_directory = create_space_for_json_export
      ogm_records = Documents::OgmRecord.all
      ogm_records.each do |record|
        document = record.metadata
        corresponding_bbox_rec = Documents::BboxCoordinates.find(record._id)
        unless corresponding_bbox_rec.nil?
          document['georss_box_s'] = corresponding_bbox_rec.to_georss_box
          document['georss_polygon_s'] = corresponding_bbox_rec.to_georss_polygon
          document['solr_geom'] = corresponding_bbox_rec.to_solr_geom
        end
        FileUtils.mkdir_p(export_directory + '/' + record.relative_path)
        File.open(export_directory + '/' + record.relative_path + '/geoblacklight.json', 'w') do |f|
          f.write(JSON.pretty_generate(document))
        end
      end
    end


    ## Database methods

    def self.pull_from_git
      Dir.glob("tmp/git/*").map { |dir| system "cd #{dir} && git pull origin master" if dir =~ /.*(edu|org|uk)\..*./ }

      record_paths = []
      Find.find('tmp/git') do |path|
        record_paths << path if path =~ /.*\.(json)$/i
      end
      record_paths
    end

    def self.pull_from_dspace(collection_id)
      event = SdrToolkit::FdaRestEvent.new()
      puts event
      to_return = event.get_collection_metadata(collection_id)
      event.logout
      return to_return
    end

    def self.update_mongo_git()
      Documents::OgmRecord.delete_all

      record_paths = self.pull_from_git
      record_paths.each do |record|
        rec = JSON.parse(File.read(record))
        new_rec = Documents::OgmRecord.new({:_id => rec['layer_slug_s'], :metadata => rec, :last_updated => Time.now})
        new_rec.upsert
      end
    end

    def self.update_mongo_fda()
      Documents::FdaRecord.delete_all

      public_docs = self.pull_from_dspace(ENV['SDR_PUBLIC_FDA_ID'])
      public_docs.each do |record|
        new_rec = Documents::FdaRecord.new({:_id => record['id'], :metadata => record, :last_updated => Time.now})
        new_rec.upsert
      end

      restricted_docs = self.pull_from_dspace(ENV['SDR_RESTRICTED_FDA_ID'])
      restricted_docs.each do |record|
        new_rec = Documents::FdaRecord.new({:_id => record['id'], :metadata => record, :last_updated => Time.now})
        new_rec.upsert
      end
    end

    def self.update_db()
      update_mongo_git
      update_mongo_fda
    end

  end
end