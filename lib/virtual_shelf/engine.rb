module VirtualShelf
  class Engine < ::Rails::Engine
    isolate_namespace VirtualShelf
    
    initializer "virtual_shelf.assets.precompile" do |app|
      app.config.assets.precompile += %w(virtual_shelf/catalog/load.js)
    end
           
    def self.mounted_path
      route = Rails.application.routes.routes.detect do |route|
        route.app == self
      end
      route && route.path
    end
    
  end
end
