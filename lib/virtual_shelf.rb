require 'twitter/bootstrap/rails/engine'
require 'net/http'
require 'squeel'
require 'virtual_shelf/engine'

module VirtualShelf
  
  def self.config
    yield Engine.config if block_given?
    Engine.config
  end
  
end
