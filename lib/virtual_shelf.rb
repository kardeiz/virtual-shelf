require 'twitter/bootstrap/rails/engine'
require "virtual_shelf/engine"

ENV['NLS_LANG'] ||= "AMERICAN_AMERICA.UTF8"

module VirtualShelf
  
  def self.config
    yield Engine.config if block_given?
    Engine.config
  end
  
end
