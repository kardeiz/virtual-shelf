require 'twitter/bootstrap/rails/engine'
require 'net/http'
require 'squeel'
require 'virtual_shelf/engine'
require 'virtual_shelf/pager'

module VirtualShelf
  
  def self.config
    yield Engine.config if block_given?
    Engine.config
  end
  
end
