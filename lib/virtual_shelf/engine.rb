module VirtualShelf
  class Engine < ::Rails::Engine
    isolate_namespace VirtualShelf
    
    initializer "virtual_shelf.assets.precompile" do |app|
      app.config.assets.precompile += %w(virtual_shelf/catalog/load.js)
    end
    
  end
end
