require_dependency "virtual_shelf/application_controller"

module VirtualShelf
  class RecordsController < ApplicationController
  
    def show
      @page, id = params[:page].to_i, params[:id]      
      set_session_params; e = session[:exclude_periodicals]
      @records = begin
        VirtualShelf::Pager.new(id, @page, e).records_for_page
      rescue
        error_page and return
      end
      
      respond_to do |format|
        format.html do
          conditional_response(@records.nil?, params[:js])     
        end
      end
    end
    
    def conditional_response(records_nil, params_js)
      return redirect_to :back if records_nil
      return render(:action => :show, :layout => false) if params_js
      render :show
    end
    
    def error_page
      render(:action => 'error', :locals => { 
        :document_number => params[:id]
      })
    end
    
    def set_session_params
      if @page.zero?
        session[:exclude_periodicals] = !(params[:include_periodicals] == '1')
        session[:document_number] = params[:id]
      end
    end
    
  end
end
