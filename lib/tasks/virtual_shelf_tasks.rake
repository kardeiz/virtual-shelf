require 'csv'

namespace :virtual_shelf do
  
  task :load_records => :environment do
    require_relative '../virtual_shelf/load_helpers'
    file_loads
  end
  
  task :load_recent_records => :environment do
    require_relative '../virtual_shelf/load_helpers'
    file_loads(true)
  end
  
  def load_joined_csv(files)
    return if File.exists?(files['zall'])
    _bash = %Q{
      join -t $'\\t' -1 1 -2 1 -a 1 
      <(sort #{files['z11']}) 
      <(sort -u -t $'\\t' -k1,1 #{files['z30']}) 
      > #{files['zall']}
    }.strip.gsub(/\s+/,' ')
    system("bash", "-c", _bash)
  end
  
  def file_loads(update = false)
    files = file_names(update)
    load_csv(files['z11'], VirtualShelf::SqlHelper.load_records(update))
    load_csv(files['z30'], VirtualShelf::SqlHelper.load_supplements(update))
    load_joined_csv(files)
    load_table(files['zall'], 'virtual_shelf_records_1', record_mappings, update)
  end
  
  def file_names(update)
    files = %w{ z11 z30 zall }.inject({}) do |h, x|
      h[x] = File.join([
        Rails.root, 'tmp', "#{!update ? x : x + '_recent'}.txt"
      ]); h
    end
  end
  
  def load_csv(file, cursor)
    CSV.open(file, 'w', :col_sep => "\t") do |csv|
      while r = cursor.fetch do 
        csv << r.map{|i| i.nil? ? '\N' : i }
      end
    end # unless File.exists?(file)
  end
  
  def _load_table(file, table, mappings)
    execute_sql(%Q{
      LOAD DATA LOCAL INFILE '#{file}' IGNORE
      INTO TABLE #{table}
      FIELDS OPTIONALLY ENCLOSED BY '"'
      (#{mappings.join(", ")})
    }.strip)
  end
  
  def load_table(file, table, mappings, update)
    return _load_table(file, table, mappings) unless update
    setters = mappings[1..-1].map do |m|
      "#{m} = VALUES(#{m})"
    end.join(', ')
    ActiveRecord::Base.transaction do
      execute_sql("CREATE TEMPORARY TABLE temp_table LIKE #{table}")
      _load_table(file, 'temp_table', mappings)
      execute_sql(%Q{
        INSERT INTO #{table}
        SELECT * FROM temp_table
        ON DUPLICATE KEY UPDATE #{setters}
      }.strip.gsub(/\s+/,' '))
      execute_sql("DROP TEMPORARY TABLE temp_table")
    end
  end
  
  def record_mappings
    %w{ document_number call_number_sort call_number year isbn oclc title summary contents is_serial material_code collection_code call_number_type }
  end
  
  def execute_sql(sql)
    ActiveRecord::Base.connection.execute(sql)
  end  
  
end
