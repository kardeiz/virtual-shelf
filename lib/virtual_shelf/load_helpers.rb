require 'fastercsv'
require "activerecord-import/base"
ActiveRecord::Import.require_adapter('mysql2')

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
        
    scope :with_helpers, lambda {
      joins { [ z13.outer, z13u.outer ] }
    }
    
    scope :with_helpers_recent, lambda {
      joins { [ z13.inner, z13u.outer ] }.merge(Z13.recent_items)
    }    
    
    scope :lcb_items, lambda { where { z11_rec_key.matches 'LCB%' } }
    
    scope :for_load_records, lambda { |update|
      _scope = update ? with_helpers_recent : with_helpers
      _scope.lcb_items._select.merge(Z13._select).merge(Z13u._select)
    }
    
    scope :_select, lambda {
      select do [ 
        trim(z11_doc_number).as(document_number), 
        trim(z11_rec_key).as(call_number_sort),
        trim(z11_text).as(call_number)          
      ] end
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
        z13_update_date.gteq my{ (8.days.ago).strftime("%Y%m%d") }
      end
    }
    
    scope :_select, lambda { select { z13_year.as(year) } }
    
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
    
    def self.get_column_codes(field)
      "#{VirtualShelf.config.send(field.to_sym)}_code".to_sym
    end
    
    def self.get_column_keys(field)
      VirtualShelf.config.send(field.to_sym).to_sym
    end
    
    scope :_select, lambda {
      select do [
        decode(trim(my{get_column_codes 'isbn_field'}), '020', upper(coalesce(regexp_substr(replace(my{get_column_keys 'isbn_field'},'-'), '[0-9Xx]{10,13}'), lpad(regexp_substr(replace(my{get_column_keys 'isbn_field'},'-'), '[0-9Xx]{1,9}'), 10, '0'))), nil).as(:isbn),            
        decode(trim(my{get_column_codes 'oclc_field'}), '035', regexp_substr(my{get_column_keys 'oclc_field'}, '[0-9]+'), nil).as(:oclc),
        regexp_replace(rtrim(concat(concat(rtrim(concat(concat(trim(my{get_column_keys 'title1_field'}), ' '), trim(my{get_column_keys 'title2_field'})), ' '), ' / '), trim(my{get_column_keys 'author_field'})), ',/ '), '\s+/\s+/\s+', ' / ').as(:title),
        trim(my{get_column_keys 'summary_field'}).as(:summary),
        trim(my{get_column_keys 'contents_field'}).as(:contents),
        instr(substr(my{get_column_keys 'ldr_field'}, 2, 1),'s').as(:is_serial)
      ] end
    }
    
    
  end if Rails.configuration.database_configuration["oracle_db"]  
  
  class Z30 < ActiveRecord::Base
    
    establish_connection(ORACLE_DB)

    self.table_name = VirtualShelf.config.z30_table_name
    self.primary_key = 'z30_rec_key'
    scope :recent_items, lambda {
      where{ z30_update_date.gteq my{ (8.days.ago).strftime("%Y%m%d") } }
    }
    
    scope :for_supplements, lambda { |update|
      _scope = update ? recent_items : scoped
      _scope.select do [
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
  
  class OracleConnection
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
        Z11.for_load_records(update).to_sql
      end
      
      def supplements_sql(update = false)
        w1, w2 = Z103.for_supplements.to_sql, Z30.for_supplements(update).to_sql
        _supplements_sql(w1, w2)
      end
      
      def _supplements_sql(t1_sql, t2_sql)
        %Q{
          with t1 as (#{t1_sql}), t2 as (#{t2_sql})
          select t1.tcu01_key, t2.material_code, t2.collection_code, t2.call_number_type
          from t1 inner join t2 on t1.tcu50_key = t2.tcu50_key
        }.strip.gsub(/\s+/,' ')        
      end      
    end
  end
  
  class InitialLoadRecordHelper  
    class << self   
    
      def do_load_records
        load_csv_for_oracle(files['records'], OracleConnection.load_records)
        load_csv_for_oracle(files['supplements'], OracleConnection.load_supplements)
        #load_csv_for_mysql(files['isbns'], execute_sql(VirtualShelf::IsbnCover._select.to_sql))
        #load_csv_for_mysql(files['oclcs'], execute_sql(VirtualShelf::OclcCover._select.to_sql))
        create_load_files(files['records'], files['supplements'], files['isbns'], files['oclcs'], load_dir)
        load_from_split
      end
      
      def load_from_split
        ActiveRecord::Base.transaction do 
          Dir[File.join(load_dir, "x*")].each_with_index do |f,i|
            load_table(f, table, mappings)
          end
        end
      end
      
      def load_csv_for_oracle(file, cursor)
        FasterCSV.open(file, 'w', :col_sep => "\t") do |csv|
          while r = cursor.fetch do 
            csv << r.map{|x| x.respond_to?(:gsub) ? x.gsub(/\\$/) { '\\\\' } : x }
          end
        end
      end
      
      def load_csv_for_mysql(file, cursor)
        FasterCSV.open(file, 'w', :col_sep => "\t") do |csv|
          cursor.each do |r|
            csv << r
          end
        end
      end
       
      def create_load_files(if1, if2, if3, if4, od)
        _bash = %Q{
          join -t $'\\t' -1 1 -2 1 -a 1 -o auto
          <(sort #{if1}) <(sort -u -t $'\\t' -k1,1 #{if2}) | 
          sort -t $'\\t' -k5,5 |
          join -t $'\\t' -1 5 -2 1 -a 1 -o auto - 
          <(sort -u -t $'\\t' -k1,1 #{if3}) |
          sort -t $'\\t' -k6,6 |
          join -t $'\\t' -1 6 -2 1 -a 1 -e '\\N' -o auto - 
          <(sort -u -t $'\\t' -k1,1 #{if4}) |
          (cd #{od}; split -l 10000)
        }.strip.gsub(/\s+/,' ')
        system("bash", "-c", _bash)
      end     
       
      def files
        @_files ||= %w{ records supplements isbns oclcs }.inject({}) do |h, x|
          h[x] = File.join(Rails.root, 'tmp', "#{x}.txt"); h
        end
      end    
          
      def load_dir
        File.join(Rails.root, 'tmp/load').tap do |_dir|
          FileUtils.mkdir(_dir) unless File.exists?(_dir)
        end
      end
            
      def load_table(file, _table, _mappings)        
        execute_sql(%Q{
          LOAD DATA LOCAL INFILE '#{file}' IGNORE
          INTO TABLE #{_table}
          FIELDS OPTIONALLY ENCLOSED BY '"'
          (#{_mappings.join(", ")})
          SET cid = COALESCE(@isbn_cid, @oclc_cid)
        }.strip)
      end
      
      def execute_sql(sql)
        ActiveRecord::Base.connection.execute(sql)
      end 
      
      def table
        'virtual_shelf_records_1'
      end 
           
      def mappings
        %w{ oclc isbn document_number call_number_sort call_number year title
        summary contents is_serial material_code collection_code
        call_number_type @isbn_cid @oclc_cid }
      end 
    
    end
  
  end
  
  class UpdateLoadRecordHelper
  
    class << self
      
      def do_load_recent_records
        create_or_update_records(OracleConnection.load_records(true))
        update_supplements(OracleConnection.load_supplements(true))
      end
      
      def update_supplements(cursor)
        iterate_over_cursor(cursor) do |o|
          o.uniq{|y| y.first}.each do |x|
            update_supplement(x)
          end
        end
      end
      
      def create_or_update_records(cursor)
        cursor = OracleConnection.load_records(true)
        iterate_over_cursor(cursor) do |o|
          o.uniq{|y| y.first}.each do |x|
            create_or_update_record(x)
          end
        end
      end
      
      def update_supplement(_r)
        keys = Hash[supplement_mappings.zip(_r)]
        record = VirtualShelf::Record.where({
          :document_number => keys.delete(:document_number)
        }).first
        record.update_attributes(keys) unless record.nil?
      end
      
      def create_or_update_record(_r)
        keys = Hash[record_mappings.zip(_r)]
        record = VirtualShelf::Record.where({
          :document_number => keys.delete(:document_number)
        }).first_or_initialize
        record.assign_attributes(keys)
        record.update_attributes(:cid => record.cover_cid)
      end
      
      
      def iterate_over_cursor(cursor, els = [])
        while r = cursor.fetch do
          els << r
          if els.size == 10000
            yield els; els = []
          end
        end
        yield els unless els.empty?
      end
      
      def record_mappings
        %w{ document_number call_number_sort call_number
        year isbn oclc title summary contents is_serial }.map(&:to_sym)
      end      
      
      def supplement_mappings
        %w{ document_number material_code
        collection_code call_number_type }.map(&:to_sym)
      end      
      
    end   
  
  end
  
end
