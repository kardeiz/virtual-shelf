module VirtualShelf
  class Z13 < ActiveRecord::Base
    
    establish_connection(:oracle_db)
    
    self.table_name = VirtualShelf.config.z13_table_name
    self.primary_key = 'z13_rec_key'
    
    belongs_to :z11, :class_name => 'Z11', :primary_key => 'z11_doc_number', :foreign_key => 'z13_rec_key'
    
    def year
      z13_year
    end
    
  end
end
