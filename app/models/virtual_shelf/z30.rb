module VirtualShelf
  class Z30 < ActiveRecord::Base
    
    establish_connection(:oracle_db)

    self.table_name = VirtualShelf.config.z30_table_name
    self.primary_key = 'z30_rec_key'

    scope :for_z11, lambda { |x|
      select1 = %Q{ 
        substr(z30_rec_key,1,9) as key, 
        max(z30_collection) as collection_code, 
        max(z30_material) as material_code
      }
      where("substr(z30_rec_key, 1,9) in (#{x})").select(select1).group('substr(z30_rec_key,1,9)')
    }
    
    def clean_collection_code
      collection_code.blank? ? nil : collection_code.to_s.strip
    end
    
    def clean_material_code
      material_code.blank? ? nil : material_code.to_s.strip
    end
    
  end if Rails.configuration.database_configuration["oracle_db"]
end
