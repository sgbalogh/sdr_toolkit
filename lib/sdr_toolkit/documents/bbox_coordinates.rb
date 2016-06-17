module Documents
  require 'mongoid'
  class BboxCoordinates
    include Mongoid::Document
    field :min_x, :type => Float
    field :max_x, :type => Float
    field :min_y, :type => Float
    field :max_y, :type => Float
    field :last_updated, :type => Time

    def to_georss_box
      if self.max_y <= 90.0
        n = self.max_y.to_s
      else
        n = '90.0'
      end

      if self.min_y >= -90.0
        s = self.min_y.to_s
      else
        s = '-90.0'
      end

      if self.max_x <= 180.0
        e = self.max_x.to_s
      else
        e = '180.0'
      end

      if self.min_x >= -180.0
        w = self.min_x.to_s
      else
        w = '-180.0'
      end

      return "#{s} #{w} #{n} #{e}"
    end

    def to_georss_polygon
      if self.max_y <= 90.0
        n = self.max_y.to_s
      else
        n = '90.0'
      end

      if self.min_y >= -90.0
        s = self.min_y.to_s
      else
        s = '-90.0'
      end

      if self.max_x <= 180.0
        e = self.max_x.to_s
      else
        e = '180.0'
      end

      if self.min_x >= -180.0
        w = self.min_x.to_s
      else
        w = '-180.0'
      end

      return "#{s} #{w} #{n} #{w} #{n} #{e} #{s} #{e} #{s} #{w}"
    end

    def to_solr_geom
      if self.max_y <= 90.0
        n = self.max_y.to_s
      else
        n = '90.0'
      end

      if self.min_y >= -90.0
        s = self.min_y.to_s
      else
        s = '-90.0'
      end

      if self.max_x <= 180.0
        e = self.max_x.to_s
      else
        e = '180.0'
      end

      if self.min_x >= -180.0
        w = self.min_x.to_s
      else
        w = '-180.0'
      end

      return "ENVELOPE(#{w}, #{e}, #{n}, #{s})"
    end
  end
end