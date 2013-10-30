module VirtualShelf
  class Cover < ActiveRecord::Base
    
    self.inheritance_column = :id_name  
    validates_uniqueness_of :cid, :scope => [:id_name, :id_value]

    def url
      cid_tag = cid.blank? ? nil : cid.to_s.rjust(10,"0")
      VirtualShelf.config.thumbnails_base_url.call(cid_tag) if cid_tag
    end
    
  end
end
