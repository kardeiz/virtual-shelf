require_dependency "virtual_shelf/application_controller"

module VirtualShelf
  class CachingController < ApplicationController
  
    def google  
      def get_processed_response_body(uri)
        response = Net::HTTP.get_response(uri) rescue nil      
        (response.body).gsub(/^_\(|\);$/,'') if response
      end    
      def get_thumbnail_urls(hash)
        hash.inject({}) do |h, (k,v)|
          h[k] = v["thumbnail_url"].gsub("zoom=5","zoom=1") if v["thumbnail_url"]; h
        end
      end     
      ids = params[:ids]
      render :nothing => true and return if ids.nil?        
      @results = Rails.cache.fetch("cover_cache_#{ids}", :expires_in => VirtualShelf.config.cache_timeout) do
        uri = URI.parse("http://books.google.com/books?jscmd=viewapi&callback=_&bibkeys=#{URI.escape(params[:ids])}")
        response = JSON.parse(get_processed_response_body(uri))
        get_thumbnail_urls(response) if response
      end    
      render :json => @results  
    end
  
  end
end
