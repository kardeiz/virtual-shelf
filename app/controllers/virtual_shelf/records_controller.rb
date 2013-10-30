require_dependency "virtual_shelf/application_controller"

module VirtualShelf
  class RecordsController < ApplicationController
  
    def show
    
      record = Record.find_and_cache_by_document_number!(params[:id])
      
      render(:action => 'error', :locals => {
        :document_number => params[:id]
      }) and return if record.nil?
      
      @records = record.set_and_cache_records_window(session[:exclude_periodicals])
        
      set_session_params    
      # cache_records_before_and_after_async(@records)
      
      respond_to do |format|
        format.html
      end
    end

    def before    
      record = Record.find_and_cache_by_document_number_unscoped!(params[:id])      
      @records = record.set_and_cache_records_before(session[:exclude_periodicals])      
      # cache_records_before_and_after_async(@records)
      
      respond_to do |format|
        format.html {
          conditional_response(@records.nil?, params[:js])     
        }
      end    
    end
    
    def after      
      record = Record.find_and_cache_by_document_number_unscoped!(params[:id])      
      @records = record.set_and_cache_records_after(session[:exclude_periodicals])      
      # cache_records_before_and_after_async(@records)
      
      respond_to do |format|
        format.html {
          conditional_response(@records.nil?, params[:js])
        }
      end    
    end
    
    def conditional_response(records_nil, params_js)
      return redirect_to :back if records_nil
      return render(:action => :show, :layout => false) if params_js
      render :show
    end
    
    def cache_records_before_and_after_async(records)
      background do
        cache_records_before_async(records.first)
        cache_records_after_async(records.last)
      end
    end
    
    def cache_records_before_async(record)      
      records = record.records_before_default(session[:exclude_periodicals])
      create_cache_unless_exists("records_before_#{record.document_number}", records)
    end
    
    def cache_records_after_async(record)
      records = record.records_after_default(session[:exclude_periodicals])
      create_cache_unless_exists("records_after_#{record.document_number}", records)
    end
    
    def create_cache_unless_exists(cache_key, records)
      Rails.cache.write(cache_key, records, exp) unless Rails.cache.exist?(cache_key)
    end
    
    def background(&block)
      Thread.new do
        yield
        ActiveRecord::Base.connection.close
      end
    end
    
    def set_session_params      
      session[:exclude_periodicals] = !(params[:include_periodicals] == '1')    
      session[:document_number] = params[:id]
    end
    
  end
end
