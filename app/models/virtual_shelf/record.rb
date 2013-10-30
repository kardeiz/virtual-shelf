module VirtualShelf
  class Record < ActiveRecord::Base
    self.table_name = "virtual_shelf_records_1"
    validates_uniqueness_of :document_number
  
    has_one :cover_via_isbn, :class_name => 'IsbnCover', :primary_key => :isbn, :foreign_key => :id_value
    has_one :cover_via_oclc, :class_name => 'OclcCover', :primary_key => :oclc, :foreign_key => :id_value
    
    delegate :url, :to => :cover, :prefix => true, :allow_nil => true
    
    PERIODICAL_IDS = %w{ PERBD PERCU PERDP PERIX PERMD PERMF PERNW PERON }
    
    scope :same_call_number_type, lambda { |type|
      return scoped unless type
      where(:call_number_type => type)
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
    
    scope :with_covers, lambda {
      includes([:cover_via_isbn, :cover_via_oclc])
    }
    
    scope :prepared, lambda { |e, c|
      exclude_periodicals(e).same_call_number_type(c)
    }

    def self.find_and_cache_by_document_number!(dn)
      Rails.cache.fetch("document_#{dn}", exp) do
        self.with_covers.find_by_document_number!(dn) rescue nil          
      end
    end
    
    def self.find_and_cache_by_document_number_unscoped!(dn)
      Rails.cache.fetch("document_unscoped_#{dn}", exp) do
        self.find_by_document_number!(dn) rescue nil          
      end
    end
    
    def self.exp
      @@exp ||= { :expires_in => VirtualShelf.config.cache_timeout }
    end

    def set_and_cache_records_window(e)
      Rails.cache.fetch("records_window_#{self.document_number}", Record.exp) do
        self.records_window_default(e)
      end
    end

    def set_and_cache_records_before(e)
      Rails.cache.fetch("records_before_#{self.document_number}", Record.exp) do
        self.records_before_default(e)
      end
    end

    def set_and_cache_records_after(e)
      Rails.cache.fetch("records_after_#{self.document_number}", Record.exp) do
        self.records_after_default(e)
      end
    end

    def records_window(before, after, e, c)
      records_before(before, e, c) +
      [self] + 
      records_after(after, e, c)
    end
    
    def records_before(before, e, c)
      Record.prepared(e, c).with_covers.records_before(self.call_number_sort, before).to_a.reverse
    end
    
    def records_after(after, e, c)
      Record.prepared(e, c).with_covers.records_after(self.call_number_sort, after).to_a
    end
    
    def records_window_default(e)
      records_before(7, e, self.call_number_type) +
      [self] + 
      records_after(7, e, self.call_number_type)
    end
    
    def records_before_default(e)      
      records_before(15, e, self.call_number_type)
    end
    
    def records_after_default(e)
      records_after(15, e, self.call_number_type)
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
      collection_code.nil?
    end

    def cover
      cover_via_isbn || cover_via_oclc
    end
    
    def has_cover?
      !cover.nil?
    end

    def cover_background_image
      "background-image: url(#{cover_url});" if has_cover?
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
      as_json(:only => [
        :isbn, :oclc, :summary, :contents
      ]).merge(custom_includes)
    end
    
    def lib_link
      VirtualShelf.config.catalog_link + document_number
    end
    
  end
end
