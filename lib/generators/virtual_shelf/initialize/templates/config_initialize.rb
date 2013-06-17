require 'virtual_shelf'

VirtualShelf.config do |config|
  config.catalog_link = 'http://libweb.lib.tcu.edu/F/?func=direct&doc_library=TCU01&doc_number='
  config.copyright_statement = '&copy; TCU Library 2013'
  config.cache_timeout = 30.minutes
  config.thumbnails_base_url = lambda {|cid_tag|
    "http://specoll.lib.tcu.edu/virtualshelf/covers_#{cid_tag[0..3]}_#{cid_tag[4..5]}/#{cid_tag}-M.jpg" 
  }
  config.z11_table_name = 'TCU01.Z11'
  config.z13_table_name = 'TCU01.Z13'
  config.z13u_table_name = 'TCU01.Z13U'
  config.z30_table_name = 'TCU50.Z30'
  config.z13u_isbn_field = 'z13u_user_defined_1'
  config.z13u_oclc_field = 'z13u_user_defined_3'
  config.z13u_contents_field = 'z13u_user_defined_4'
  config.z13u_summary_field = 'z13u_user_defined_5'
  config.z13u_title1_field = 'z13u_user_defined_6'
  config.z13u_title2_field = 'z13u_user_defined_7'
  config.z13u_author_field = 'z13u_user_defined_8'
  config.z13u_ldr_field = 'z13u_user_defined_9'
  
  config.icons = {
    
  }  
end
