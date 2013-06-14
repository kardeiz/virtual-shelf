module VirtualShelf
  class Record < ActiveRecord::Base
  
    validates_uniqueness_of :document_number
  
    has_one :cover_via_isbn, :class_name => 'IsbnCover', :primary_key => :isbn, :foreign_key => :id_value
    has_one :cover_via_oclc, :class_name => 'OclcCover', :primary_key => :oclc, :foreign_key => :id_value
    
    delegate :url, :to => :cover, :prefix => true, :allow_nil => true
    
    scope :exclude_periodicals, lambda { |x|
      return scoped unless x
      per_ids = ['PERBD','PERCU','PERDP','PERIX','PERMD','PERMF','PERNW','PERON']
      where_1 = %Q{collection_code not in (?) or collection_code is null}
      where_2 = %Q{collection_code is not null or is_serial is false}
      where(where_1, per_ids).where(where_2)
    }
    
    scope :records_before, lambda {|x,y| 
      where("call_number_sort < ?", x).order("call_number_sort desc").limit(y) 
    }
    scope :records_after,  lambda {|x,y| 
      where("call_number_sort > ?", x).order("call_number_sort asc").limit(y)
    }
    
    default_scope lambda {
      includes([:cover_via_isbn, :cover_via_oclc])
    } 

    def format  
      return (is_serial ? "[ONLINE JOURNAL]" : "[ONLINE BOOK]") if is_electronic_resource?
      return "[AUDIO RECORDING]" if %w{ADISC ATAPE}.include? material_code
      return "[PRINT JOURNAL]" if %w{ISSBD ISSUE NEWSP}.include? material_code
      return "[MAP]" if %w{MAP}.include? material_code
      return "[VIDEO RECORDING]" if %w{MEDIA VDISC VTAPE}.include? material_code
      return "[MICROFORM]" if %w{MCARD MFICH MFILM MICRO}.include? material_code
      return "[MUSICAL SCORE]" if %w{SCORE SHEET}.include? material_code
    end

    def is_electronic_resource?
      collection_code.nil?
    end

    def cover
      cover_via_isbn || cover_via_oclc
    end
    
    def has_cover?
      cover.nil? ? false : true
    end

    def cover_background_image
      "background-image: url(#{cover_url});" if has_cover?
    end

    def records_window(num_before, num_after, x)
      Record.exclude_periodicals(x).records_before(self.call_number_sort, num_before).to_a.reverse +
      [self] + 
      Record.exclude_periodicals(x).records_after(self.call_number_sort, num_after).to_a
    end
    
    def clean_call_number
      call_number.gsub("$$a","").gsub("$$b"," ") if call_number.respond_to?(:gsub)
    end
      
    def title_with_format
      [title, format].compact.join(" ")
    end
    
    def hash_for_js
      custom_includes = { 
        'call-number' => clean_call_number, 
        'document-number' => document_number, 
        'title-with-format' => title_with_format, 
        'date' => year
      }
      as_json(:only => [:isbn, :oclc, :summary, :contents, :title]).merge(custom_includes)
    end
    
    def lib_link
      VirtualShelf.config.catalog_link + document_number
    end
    
  end
end
