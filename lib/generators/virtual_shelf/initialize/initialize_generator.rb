module VirtualShelf
  module Generators
    class InitializeGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)
      
      def copy_initializer_file
        copy_file "config_initialize.rb", "config/initializers/virtual_shelf_initialize.rb"
      end
      
      def write_line_to_routes
        insert_into_file 'config/routes.rb', 
          %Q{\n  mount VirtualShelf::Engine => "/"},
          :after => /.*?\.routes\.draw do\n/
        
        insert_into_file 'config/application.rb', 
          %Q{\nrequire 'virtual_shelf'\nENV['NLS_LANG'] ||= "AMERICAN_AMERICA.UTF8"\n}, 
          :after => /require 'rails\/all'\n/
        
        
      end
      
    end
  end
end
