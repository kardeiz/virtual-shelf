require_dependency "virtual_shelf/application_controller"

module VirtualShelf
  class RecordsController < ApplicationController
  
    before_filter :set_common_variables
    before_filter :set_session_params, :only => :show
  
    def show      
      return error_page unless @record
    
      @records = Rails.cache.fetch("window/#{@id}/#{@e}", cache_opts) do
        @record.records_window(7, 7, @e)
      end            
      responder
    end
    
    def before      
      @records = Rails.cache.fetch("before/#{@id}/#{@e}", cache_opts) do
        @record.records_before(15, @e)
      end      
      responder     
    end
    
    def after      
      @records = Rails.cache.fetch("after/#{@id}/#{@e}", cache_opts) do
        @record.records_after(15, @e)
      end      
      responder     
    end
    
    def responder
      respond_to do |format|
        format.html do
          if @records.blank?  then redirect_to :back 
          elsif params[:js]   then render(:action => :show, :layout => false)
          else render :show end
        end
      end
    end
    
    def error_page
      render(:action => 'error', :locals => { 
        :document_number => @id
      })
    end
    
    def set_common_variables
      @id, @e = params[:id], session[:exclude_periodicals]
      @record = Rails.cache.fetch("document/#{@id}", cache_opts) do
        Record.find_by_document_number(@id)
      end
    end
    
    def set_session_params
      session[:exclude_periodicals] = params[:include_periodicals] != '1'
      session[:document_number] = params[:id]
    end
    
    def cache_opts
      { :expires_in => VirtualShelf.config.cache_timeout }
    end
    
  end
end
