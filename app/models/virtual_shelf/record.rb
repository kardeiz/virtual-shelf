module VirtualShelf
  class Record < ActiveRecord::Base
    self.table_name = "virtual_shelf_records_1"
    validates_uniqueness_of :document_number
    attr_accessible :document_number, :call_number_sort, :call_number, :year,
      :isbn, :oclc, :title, :summary, :contents, :is_serial, :material_code,
      :collection_code, :call_number_type
  
    has_one :cover_via_isbn, {
      :class_name => 'IsbnCover', 
      :primary_key => :isbn, 
      :foreign_key => :id_value
    }
    has_one :cover_via_oclc, {
      :class_name => 'OclcCover',
      :primary_key => :oclc,
      :foreign_key => :id_value
    }
    
    scope :set_index, lambda { |c|
      index = if [0, nil, 3].include?(c)
        'index_virtual_shelf_records_1_multi_column'
      else 
        'index_virtual_shelf_records_1_on_call_number_type'
      end      
      from("#{quoted_table_name} use index(#{index})")
    }
    
    delegate :cid, :to => :cover, :prefix => true, :allow_nil => true
    
    PERIODICAL_IDS = %w{ PERBD PERCU PERDP PERIX PERMD PERMF PERNW PERON }
    
    scope :same_call_number_type, lambda { |type|
      where(:call_number_type => type)
    }
    
    scope :with_covers, lambda {
       includes([:cover_via_isbn, :cover_via_oclc])
    }
    
    scope :exclude_periodicals, lambda { |exclude|
      return scoped unless exclude
      where do
        ((collection_code.not_in PERIODICAL_IDS) | (collection_code.eq nil)) & 
        ((collection_code.not_eq nil) | (is_serial.eq false))
      end
    }
    
    scope :records_before, lambda {|before, _limit| 
      where { 
        call_number_sort.lt before
      }.order{ call_number_sort.desc }.limit(_limit) 
    }
    scope :records_after,  lambda {|after, _limit| 
      where { 
        call_number_sort.gt after
      }.order{ call_number_sort.asc }.limit(_limit)
    }
    
    scope :prepared, lambda { |e, c|
      exclude_periodicals(e).same_call_number_type(c).set_index(c).with_covers
    }
    
    def records_before(before, e)
      Record.prepared(e, self.call_number_type).records_before(self.call_number_sort, before).to_a.reverse
    end
    
    def records_after(after, e)
      Record.prepared(e, self.call_number_type).records_after(self.call_number_sort, after).to_a
    end
    
    def records_window(before, after, e)
      records_before(before, e) + [self] + records_after(after, e)
    end
    
    def format
      if is_electronic_resource?
        return is_serial ? "[ONLINE JOURNAL]" : "[ONLINE BOOK]"
      end
      case material_code
      when /ADISC|ATAPE/ then "[AUDIO RECORDING]"
      when /ISSBD|ISSUE|NEWSP/ then "[PRINT JOURNAL]"
      when /MAP/ then "[MAP]"
      when /MEDIA|VDISC|VTAPE/ then "[VIDEO RECORDING]"
      when /MCARD|MFICH|MFILM|MICRO/ then "[MICROFORM]"
      when /SCORE|SHEET/ then "[MUSICAL SCORE]"
      else nil end
    end

    def is_electronic_resource?
      collection_code.blank?
    end

    def cover
      cover_via_isbn || cover_via_oclc
    end
    
    def has_cover?
      !cover_cid.blank?
    end

    def cover_url
      cid_tag = cover_cid.blank? ? nil : cover_cid.to_s.rjust(10,"0")
      VirtualShelf.config.thumbnails_base_url.call(cid_tag) if cid_tag
    end

    def cover_background_image
      "background-image: url(#{cover_url});" if has_cover?
    end
    
    def clean_call_number
      if call_number.respond_to?(:gsub)
        call_number.gsub("$$a","").gsub("$$b"," ") 
      end
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
      as_json(:only => [
        :isbn, :oclc, :summary, :contents
      ]).merge(custom_includes)
    end
    
    def lib_link
      VirtualShelf.config.catalog_link + document_number
    end
    
  end
end
