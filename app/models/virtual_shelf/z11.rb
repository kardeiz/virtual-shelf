module VirtualShelf
  class Z11 < ActiveRecord::Base
    
    establish_connection(:oracle_db)

    self.table_name = VirtualShelf.config.z11_table_name
    self.primary_key = 'z11_rec_key'
    
    has_one :z13u, :class_name => 'Z13u', :primary_key => 'z11_doc_number', :foreign_key => 'z13u_rec_key'
    has_one :z13, :class_name => 'Z13', :primary_key => 'z11_doc_number', :foreign_key => 'z13_rec_key'

    z13u_methods = [
      :isbn_cleaned,
      :oclc_cleaned,
      :contents_cleaned, 
      :summary_cleaned,
      :title_statement,
      :is_serial?
    ]
    z13u_delegate_options = { :to => :z13u, :prefix => true, :allow_nil => true }    
    delegate *(z13u_methods << z13u_delegate_options)
     
    delegate :year, :to => :z13, :prefix => true, :allow_nil => true
   
    scope :include_helper_tables, includes([:z13u, :z13])

    scope :lcb_items, lambda { where("z11_rec_key like 'LCB%'") }

    scope :recent_items, lambda {
      joins(:z13).where("z13_update_date > (?)", (1.week.ago).strftime("%Y%m%d"))
    }
    
    scope :iterator, lambda {|x,y| where("z11_rec_key > ?", x).order("z11_rec_key asc").limit(y) }  

    def self.loop(limiter, &blk)
      set = limit(limiter)
      _z30s = VirtualShelf::Z30.for_z11(set.select(:z11_doc_number).to_sql).all
      return nil if set.empty?      
      yield set.all, _z30s
      iterator(set.last.z11_rec_key, limiter).loop(limiter, &blk)
    end
        
    def call_number
      z11_text.to_s.strip unless z11_text.nil? 
    end
    
    def document_number
      z11_doc_number.to_s.strip unless z11_doc_number.nil?
    end
    
    def call_number_for_sort
      z11_rec_key.to_s.strip unless z11_rec_key.nil?
    end
    
    private
    
    def self.z30_hash(z30s)
      z30s.inject({}) do |h,v|
        h[v.key] = [v.clean_collection_code, v.clean_material_code]; h
      end
    end
    
  end
end
