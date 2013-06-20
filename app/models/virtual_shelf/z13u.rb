module VirtualShelf
  class Z13u < ActiveRecord::Base
    
    establish_connection(:oracle_db)
    
    self.table_name = VirtualShelf.config.z13u_table_name
    self.primary_key = 'z13u_rec_key'
    
    belongs_to :z11, :class_name => 'Z11', :primary_key => 'z11_doc_number', :foreign_key => 'z13u_rec_key'
    
    def isbn_cleaned
      if user_defined_is_isbn?
        return_value = z13u_isbn_field.to_s.match(/\b[\dXx]{1,13}\b/)
        return_value.to_s.strip.rjust(10,'0') if return_value
      end
    end
    
    def oclc_cleaned
      if user_defined_is_oclc?
        return_value = z13u_oclc_field.to_s.scan(/\d+/).first
        return_value.to_s.strip if return_value
      end
    end
    
    def title_cleaned 
      if user_defined_is_title1? && user_defined_is_title2?
        return_value = [z13u_title1_field, z13u_title2_field].reject(&:blank?).join(" ")
        return_value.blank? ? nil : return_value
      end    
    end
    
    def summary_cleaned
      z13u_summary_field.to_s unless !user_defined_is_contents? || z13u_summary_field.blank?
    end
    
    def contents_cleaned
      z13u_contents_field.to_s unless !user_defined_is_summary? || z13u_contents_field.blank?
    end
    
    def author_cleaned
      z13u_author_field.to_s unless !user_defined_is_author? || z13u_author_field.blank?
    end
    
    def title_statement
      return_value = [title_cleaned, author_cleaned].compact.join(" / ").gsub(" / / "," / ")
      return_value.blank? ? nil : return_value
    end
    
    def is_serial?
      return false if !user_defined_is_ldr? || z13u_ldr_field.blank?
      z13u_ldr_field.to_s.slice(1,1) == 's'
    end
         
    def user_defined_is_isbn?
      z13u_isbn_field_code.to_s.match(/020/) ? true : false
    end
    
    def user_defined_is_oclc?
      z13u_oclc_field_code.to_s.match(/035/) ? true : false
    end
    
    def user_defined_is_contents?
      z13u_contents_field_code.to_s.match(/505/) ? true : false
    end
    
    def user_defined_is_summary?
      z13u_summary_field_code.to_s.match(/520/) ? true : false
    end
    
    def user_defined_is_title1?
      z13u_title1_field_code.to_s.match(/245/) ? true : false
    end
    
    def user_defined_is_title2?
      z13u_title2_field_code.to_s.match(/245/) ? true : false
    end
    
    def user_defined_is_author?
      z13u_author_field_code.to_s.match(/100/) ? true : false
    end
    
    def user_defined_is_ldr?
      z13u_ldr_field_code.to_s.match(/LDR/) ? true : false
    end   
    
    private
    
    [ 
      :z13u_isbn_field,
      :z13u_oclc_field,
      :z13u_contents_field,
      :z13u_summary_field,
      :z13u_title1_field,
      :z13u_title2_field,
      :z13u_author_field,
      :z13u_ldr_field
    ].each do |md|      
      define_method md do
        tm = VirtualShelf.config.send(md)
        self.send(tm)
      end
      
      define_method md.to_s + '_code' do
        tm = VirtualShelf.config.send(md)
        self.send(tm + '_code')
      end      
    end
    
  end if Rails.configuration.database_configuration["oracle_db"]
end
