require 'csv'

namespace :virtual_shelf do
  
  task :load_records => :environment do
    VirtualShelf::Record.delete_all
    VirtualShelf::Z11.include_helper_tables.lcb_items.order("z11_rec_key asc").loop(1000) do |load_records, _z30s|
      ActiveRecord::Base.transaction do
        load_records.each do |lr|
          _z30 = _z30s.detect{|x| x.key == lr.document_number}
          create_record(lr, _z30)  
        end
      end
      puts "Record.count = #{VirtualShelf::Record.count}"
    end
  end
  
  task :load_recent_records => :environment do
    VirtualShelf::Z11.lcb_items.recent_items.include_helper_tables.loop(nil) do |load_records, _z30s|
      ActiveRecord::Base.transaction do
        load_records.each do |lr|          
          _z30 = _z30s.detect{|x| x.key == lr.document_number}
          create_record(lr, _z30)
        end
      end
    end
    puts "Record.count = #{VirtualShelf::Record.count}"
  end
  
  task :load_covers => :environment do  
    file = ENV['filename']
    next unless file
    
    ActiveRecord::Base.transaction do
      CSV.foreach(file, {:col_sep => "\t"}) do |row|
        type = if row[0] == 'isbn'
          'VirtualShelf::IsbnCover'
        elsif row[0] == 'oclc'
          'VirtualShelf::OclcCover'
        end
        
        Cover.create do |cover|
          cover.cid = row[3].to_i
          cover.id_name = type
          cover.id_value = row[1]
        end if type
      end
    end
  end
  
  
  
  def create_record(lr, _z30)
    VirtualShelf::Record.create do |nr, _z30|        
      nr.call_number = lr.call_number
      nr.call_number_sort = lr.call_number_for_sort
      nr.document_number = lr.document_number
      nr.isbn = lr.z13u_isbn_cleaned
      nr.oclc = lr.z13u_oclc_cleaned
      nr.contents = lr.z13u_contents_cleaned
      nr.summary = lr.z13u_summary_cleaned
      nr.title = lr.z13u_title_statement
      nr.is_serial = lr.z13u_is_serial?
      nr.year = lr.z13_year
      nr.collection_code = _z30.collection_code unless _z30.nil?
      nr.material_code = _z30.material_code unless _z30.nil?
    end
  end
  
  
end
