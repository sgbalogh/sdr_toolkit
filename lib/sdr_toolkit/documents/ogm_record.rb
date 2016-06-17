module Documents
  require 'mongoid'
  class OgmRecord
    include Mongoid::Document
    field :metadata, :type => Hash
    field :last_updated, :type => Time

    def relative_path
      return "edu.nyu/handle/2451/#{self._id.split('_')[-1]}"
    end

  end
end