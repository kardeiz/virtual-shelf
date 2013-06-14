module VirtualShelf
  class Cover < ActiveRecord::Base
    
    self.inheritance_column = :id_name  
    validates_uniqueness_of :cid, :scope => [:id_name, :id_value]

    def url
      cid_tag = cid.blank? ? nil : cid.to_s.rjust(10,"0")
      if cid_tag
        url_string = VirtualShelf.config.thumbnails_base_url.call(cid_tag)
        # "/caching/passthrough?url=#{ URI.escape(url_string) }"
      end
    end
    
  end
end
