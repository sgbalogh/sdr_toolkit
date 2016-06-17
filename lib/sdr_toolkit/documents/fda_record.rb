module Documents
  require 'mongoid'
  class FdaRecord
    include Mongoid::Document
    field :metadata, :type => Hash
    field :last_updated, :type => Time

    def slugify
      return 'nyu_' + self.metadata['handle'].gsub('/','_') unless self.metadata['handle'].blank?
    end

    def urlify
      return 'https://archive.nyu.edu/handle/' + self.metadata['handle'] unless self.metadata['handle'].blank?
    end

  end
end