module VirtualShelf
  module Generators
    class InitializeGenerator < Rails::Generators::Base
      def project_create
        create_file "config/initializers/initializer.rb", "# Add initialization content here"
      end
    end
  end
end
