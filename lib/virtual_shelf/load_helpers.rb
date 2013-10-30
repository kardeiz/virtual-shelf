module VirtualShelf
  
  ORACLE_DB = Rails.configuration.database_configuration["oracle_db"]
  
  class Z11 < ActiveRecord::Base    
    establish_connection(ORACLE_DB)

    self.table_name = VirtualShelf.config.z11_table_name
    self.primary_key = 'z11_rec_key'
    
    has_one :z13u, {
      :class_name => 'Z13u', 
      :primary_key => 'z11_doc_number', 
      :foreign_key => 'z13u_rec_key'
    }
    has_one :z13, {
      :class_name => 'Z13', 
      :primary_key => 'z11_doc_number', 
      :foreign_key => 'z13_rec_key'
    }
    def self.get_column_keys(field)
      VirtualShelf.config.send(field.to_sym).to_sym
    end
    
    scope :with_helpers, lambda {
      joins { [ z13.outer, z13u.outer ] }
    }
    
    scope :with_helpers_recent, lambda {
      joins { [ z13.inner, z13u.outer ] }.merge(Z13.recent_items)
    }    
    
    scope :lcb_items, lambda { where { z11_rec_key.matches 'LCB%' } }
    
    scope :clean_select, lambda {
      select do
        [ 
          trim(z11_doc_number).as(document_number), 
          trim(z11_rec_key).as(call_number_sort),
          trim(z11_text).as(call_number), 
          z13.z13_year.as(year), 
          { z13u => [
            coalesce(lpad(regexp_substr(regexp_substr(my{get_column_keys 'isbn_field'}, '(^|[^0-9Xx])[0-9Xx]{1,9}([^0-9Xx]|$)'), '[0-9Xx]{1,9}'), 10, '0'), regexp_substr(my{get_column_keys 'isbn_field'}, '[0-9Xx]{10,13}')).as(:isbn),            
            regexp_substr(my{get_column_keys 'oclc_field'}, '[0-9]+').as(:oclc),
            regexp_replace(rtrim(concat(concat(rtrim(concat(concat(trim(my{get_column_keys 'title1_field'}), ' '), trim(my{get_column_keys 'title2_field'})), ' '), ' / '), trim(my{get_column_keys 'author_field'})), ',/ '), '\s+/\s+/\s+', ' / ').as(:title),
            trim(my{get_column_keys 'summary_field'}).as(:summary),
            trim(my{get_column_keys 'contents_field'}).as(:contents),
            instr(substr(my{get_column_keys 'ldr_field'}, 2, 1),'s').as(:is_serial)
          ] }
        ] 
      end
    }
    
  end if Rails.configuration.database_configuration["oracle_db"]
  
  class Z13 < ActiveRecord::Base    
    establish_connection(ORACLE_DB)
    
    self.table_name = VirtualShelf.config.z13_table_name
    self.primary_key = 'z13_rec_key'
    
    belongs_to :z11, {
      :class_name => 'Z11', 
      :primary_key => 'z11_doc_number', 
      :foreign_key => 'z13_rec_key'
    }
    
    scope :recent_items, lambda {
      where do
        z13_update_date.gteq (8.days.ago).strftime("%Y%m%d")
      end
    }
  end if Rails.configuration.database_configuration["oracle_db"]
  
  class Z13u < ActiveRecord::Base    
    establish_connection(ORACLE_DB)
    
    self.table_name = VirtualShelf.config.z13u_table_name
    self.primary_key = 'z13u_rec_key'
    
    belongs_to :z11, {
      :class_name => 'Z11', 
      :primary_key => 'z11_doc_number', 
      :foreign_key => 'z13u_rec_key'
    }
  end if Rails.configuration.database_configuration["oracle_db"]  
  
  class Z30 < ActiveRecord::Base
    
    establish_connection(ORACLE_DB)

    self.table_name = VirtualShelf.config.z30_table_name
    self.primary_key = 'z30_rec_key'
    scope :recent_items, lambda {
      where{ z30_update_date.gteq (8.days.ago).strftime("%Y%m%d") }
    }
    
    scope :for_supplements, lambda {
      select do [
        substr(z30_rec_key, 1, 9).as(tcu50_key),
        trim(z30_material).as(material_code), 
        trim(z30_collection).as(collection_code), 
        z30_call_no_type.as(call_number_type)
      ] end
    }
    
  end if Rails.configuration.database_configuration["oracle_db"]
  
  class Z103 < ActiveRecord::Base
    
    establish_connection(ORACLE_DB)

    self.table_name = VirtualShelf.config.z103_table_name
    self.primary_key = 'z103_rec_key'   
    
    scope :for_supplements, lambda {
      select do [
        substr(z103_rec_key, 6, 9).as(tcu50_key), 
        substr(z103_rec_key_1, 6, 9).as(tcu01_key)
      ] end.where(:z103_lkr_type => 'ADM')
    }
    
  end if Rails.configuration.database_configuration["oracle_db"]
  
  class SqlHelper
    class << self      
      def conn
        @conn ||= Class.new(ActiveRecord::Base).establish_connection(ORACLE_DB).connection
      end
      
      def load_records(update = false)
        conn.execute(records_sql(update))
      end
      
      def load_supplements(update = false)
        conn.execute(supplements_sql(update))
      end
      
      def records_sql(update = false)
        if update then Z11.with_helpers_recent.clean_select.lcb_items.to_sql
        else Z11.with_helpers.clean_select.lcb_items.to_sql end
      end
      
      def supplements_sql(update = false)
        with_tables = [].push(Z103.for_supplements.to_sql)
        with_tables.push(update ? Z30.for_supplements.recent_items.to_sql : Z30.for_supplements.to_sql)
        sql = "with t1 as (#{with_tables[0]}), t2 as (#{with_tables[1]}) "
        sql << %Q{
          select t1.tcu01_key, t2.material_code, t2.collection_code, t2.call_number_type
          from t1 inner join t2 on t1.tcu50_key = t2.tcu50_key
        }.strip.gsub(/\s+/,' ')
      end
    end
  end
  
  
end
