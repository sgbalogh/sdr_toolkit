require 'find'
require 'json'
namespace :sdr do
  desc 'Update MongoDB representation of OGM records'
  task :pull_ogm do
    SdrToolkit::Utils.update_mongo_git
  end

  desc 'Update MongoDB representation of FDA records'
  task :pull_fda do
    SdrToolkit::Utils.update_mongo_fda
  end

  desc 'Update MongoDB'
  task :update_db do
    SdrToolkit::Utils.update_db
  end

  desc 'List FDA records without a matching OGM record'
  task :unmatched_fda do
    SdrToolkit::Utils.display_unmatched_fda_records
  end

  desc 'Remove empty unmatched FDA records'
  task :remove_empty_fda do
    SdrToolkit::Utils.delete_empty_unmatched_fda_records
  end

  desc 'Update missing bounding box values from PostGIS into DB'
  task :compute_bbox do
    SdrToolkit::Utils.compute_missing_vector_bounding_boxes
  end

  desc 'List empty containers'
  task :list_containers do
    SdrToolkit::Utils.gather_empty_containers
  end

  desc 'Upload attachments as FDA bitstreams (from tmp/bitstream_uploads)'
  task :upload_bitstreams do
    SdrToolkit::Utils.upload_bitstreams_to_fda
  end

  desc 'Create FDA containers with Handle UUIDs (specify which collection, and quantity, as arguments)'
  task :create_containers, [:collection, :quantity] do |t, args|
    if args[:collection].downcase == 'restricted' || args[:collection].downcase == 'public'
      SdrToolkit::Utils.create_containers(args[:collection], args[:quantity].to_i)
    end
  end


end