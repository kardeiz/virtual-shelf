module VirtualShelf
  class ApplicationController < ActionController::Base
  
    private
    
    def exp
      Record.exp
    end
  
    def send_http_response_data(response)
      send_data response.body, {
        :type => response['Content-Type'], :disposition => 'inline'
      }
    end
  
  end
end
