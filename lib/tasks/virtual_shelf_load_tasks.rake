require 'fastercsv'

namespace :virtual_shelf do
  
  task :load_recent_records => :environment do
    require File.expand_path('../../virtual_shelf/load_helpers', __FILE__)
    VirtualShelf::UpdateLoadRecordHelper.do_load_recent_records
  end
  
  task :load_records => :environment do
    require File.expand_path('../../virtual_shelf/load_helpers', __FILE__)
    VirtualShelf::InitialLoadRecordHelper.do_load_records
  end
  
  
end
