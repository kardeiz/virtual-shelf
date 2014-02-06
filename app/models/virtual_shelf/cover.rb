module VirtualShelf
  class Cover < ActiveRecord::Base
    
    self.inheritance_column = :id_name  
    validates_uniqueness_of :cid, :scope => [:id_name, :id_value]
    
  end
end
