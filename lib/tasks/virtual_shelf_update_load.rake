require 'fastercsv'

namespace :virtual_shelf do
  
  task :load_recent_records => :environment do
    require File.expand_path('../../virtual_shelf/load_helpers', __FILE__)
    do_load_recent_records
  end
  
  def do_load_recent_records
    load_csv(file_names['records'], records_cursor)
    load_csv(file_names['supplements'], supplements_cursor)
    load_records
    update_supplements
  end
  
  def file_names
    %w{ records supplements }.inject({}) do |h, x|
      h[x] = File.join([
        Rails.root, 'tmp', "#{x}_recent.txt"
      ]); h
    end
  end
  
  def load_csv(file, cursor)
    FasterCSV.open(file, 'w', :col_sep => "\t") do |csv|
      while r = cursor.fetch do 
        csv << r
      end
    end
  end
  
  def load_table(file, mappings)
    execute_sql(%Q{
      LOAD DATA LOCAL INFILE '#{file}' IGNORE
      INTO TABLE temp_table
      FIELDS OPTIONALLY ENCLOSED BY '"'
      (#{mappings.join(", ")})
    }.strip)
  end
  
  def load_records    
    ActiveRecord::Base.transaction do
      temp_table_wrapper do
        load_table(file_names['records'], record_mappings)
        execute_sql(load_records_sql)
      end
    end
  end
  
  def update_supplements    
    ActiveRecord::Base.transaction do
      temp_table_wrapper do
        load_table(file_names['supplements'], supplement_mappings)
        execute_sql(update_supplements_sql)
      end
    end
  end
  
  def records_cursor
    VirtualShelf::SqlHelper.load_records(true)
  end
  
  def supplements_cursor
    VirtualShelf::SqlHelper.load_supplements(true)
  end
  
  def load_records_sql
    %Q{
      INSERT INTO #{table}
      SELECT * FROM temp_table
      ON DUPLICATE KEY UPDATE #{record_setters}
    }.strip.gsub(/\s+/,' ')
  end
  
  def update_supplements_sql
    %Q{
      UPDATE #{table}
      INNER JOIN temp_table on temp_table.document_number = #{table}.document_number
      SET #{supplement_setters}
    }.strip.gsub(/\s+/,' ')
  end
  
  def temp_table_wrapper
    execute_sql("CREATE TEMPORARY TABLE temp_table LIKE #{table}")
    yield
    execute_sql("DROP TEMPORARY TABLE temp_table")
  end
  
  def record_setters
    record_mappings[1..-1].map do |m|
      "#{m} = coalesce(VALUES(#{m}), #{table}.#{m})"
    end.join(', ')
  end
  
  def supplement_setters
    supplement_mappings[1..-1].map do |m|
      "#{table}.#{m} = temp_table.#{m}"
    end.join(', ')
  end
  
  def record_mappings
    %w{ document_number call_number_sort call_number year isbn oclc title summary contents is_serial }
  end
  
  def supplement_mappings
    %w{ document_number material_code collection_code call_number_type }
  end
  
  def table
    'virtual_shelf_records_1'
  end
  
  def execute_sql(sql)
    ActiveRecord::Base.connection.execute(sql)
  end  
  
end
