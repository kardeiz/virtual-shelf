module VirtualShelf
  module Generators
    class InitializeGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)
      
      def copy_initializer_file
        copy_file "config_initialize.rb", "config/initializers/virtual_shelf_initialize.rb"
      end
      
      def write_line_to_routes
        line = /(.*?\.routes\.draw do)/mi
        gsub_file 'config/routes.rb',line do |match|
          "#{match}\n\n  mount VirtualShelf::Engine => \"/\""
        end
      end
      
    end
  end
end
