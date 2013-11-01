require 'fastercsv'

namespace :virtual_shelf do
  
  task :load_records => :environment do
    require File.expand_path('../../virtual_shelf/load_helpers', __FILE__)
    do_load_records
  end
  
  def load_joined_csv
    _bash = %Q{
      join -t $'\\t' -1 1 -2 1 -a 1 -e '\\N' -o auto
      <(sort #{file_names['records']}) 
      <(sort -u -t $'\\t' -k1,1 #{file_names['supplements']}) 
      > #{file_names['all']}
    }.strip.gsub(/\s+/,' ')
    system("bash", "-c", _bash)
  end
  
  def do_load_records
    load_csv(file_names['records'], records_cursor)
    load_csv(file_names['supplements'], supplements_cursor)
    load_joined_csv
    load_table
  end
  
  def file_names
    %w{ records supplements all }.inject({}) do |h, x|
      h[x] = File.join(Rails.root, 'tmp', "#{x}.txt"); h
    end
  end
  
  def load_csv(file, cursor)
    FasterCSV.open(file, 'w', :col_sep => "\t") do |csv|
      while r = cursor.fetch do 
        csv << r
      end
    end
  end
  
  def load_table
    execute_sql(%Q{
      LOAD DATA LOCAL INFILE '#{file_names['all']}' IGNORE
      INTO TABLE #{table}
      FIELDS OPTIONALLY ENCLOSED BY '"'
      (#{record_mappings.join(", ")})
    }.strip)
  end
  
  def records_cursor
    VirtualShelf::SqlHelper.load_records
  end
  
  def supplements_cursor
    VirtualShelf::SqlHelper.load_supplements
  end
  
  def record_mappings
    %w{ document_number call_number_sort call_number year isbn oclc title summary contents is_serial material_code collection_code call_number_type }
  end
  
  def table
    'virtual_shelf_records_1'
  end
  
  def execute_sql(sql)
    ActiveRecord::Base.connection.execute(sql)
  end  
  
end
