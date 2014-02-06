require_dependency "virtual_shelf/application_controller"

module VirtualShelf
  class CachingController < ApplicationController
  
    def books   
      render :nothing => true and return unless ids = params[:ids]
      @result = Rails.cache.fetch("books/#{ids}", cache_opts) do 
        get_books_from_google(ids)
      end    
      render :json => @result
    end
  
    def thumbnails
      render :nothing => true and return unless url_string = params[:url]
      @response = Rails.cache.fetch("thumbnails/#{url_string}", cache_opts) do
        url = URI.parse(url_string)
        if url.host.include?('books.google.com')
          Net::HTTP.get_response(url) rescue nil
        else nil end
      end
      if @response
        send_http_response_data(@response)
      else render :nothing => true end  
    end
  
    private
    
    def get_books_from_google(ids)
      uri = URI.parse(google_books_url(ids))
      response = Net::HTTP.get_response(uri) rescue nil
      books_js_helper(response.body) if response
    end
    
    def google_books_url(ids)
      "http://books.google.com/books?jscmd=viewapi&callback=_&bibkeys=#{URI.escape(ids)}"
    end
    
    def books_js_helper(response)
      parsed = JSON.parse(response.gsub(/^_\(/,'').gsub(/\);/,''))
      get_thumbnail_urls(parsed)
    end
    
    def get_thumbnail_urls(hash)
      hash.inject({}) do |h, (k,v)|
        h[k] = v["thumbnail_url"].gsub("zoom=5","zoom=1") if v["thumbnail_url"]
        h
      end
    end  
  
    def cache_opts
      { :expires_in => VirtualShelf.config.cache_timeout }
    end
  
  end
end
