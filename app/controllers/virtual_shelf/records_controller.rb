require_dependency "virtual_shelf/application_controller"

module VirtualShelf
  class RecordsController < ApplicationController
  
    def show
    
      @record = Rails.cache.fetch("document_#{params[:id]}", :expires_in => VirtualShelf.config.cache_timeout) do
        begin
          Record.find_by_document_number!(params[:id])
        rescue ActiveRecord::RecordNotFound
          render(:action => 'error', :locals => { :document_number => params[:id] }) and return
        end
      end
      
      session[:exclude_periodicals] = !(params[:include_periodicals] == '1')    
      session[:document_number] = params[:id]
      
      @records = Rails.cache.fetch("records_window_#{params[:id]}", :expires_in => VirtualShelf.config.cache_timeout) do
        @record.records_window(7, 7, session[:exclude_periodicals])
      end
      
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @records }
      end
    end

    def before
    
      @record = Rails.cache.fetch("document_#{params[:id]}", :expires_in => VirtualShelf.config.cache_timeout) do
        Record.find_by_document_number!(params[:id])
      end
      
      @records = Rails.cache.fetch("records_before_#{params[:id]}", :expires_in => VirtualShelf.config.cache_timeout) do
        Record.exclude_periodicals(session[:exclude_periodicals]).records_before(@record.call_number_sort,15).to_a.reverse
      end
      
      respond_to do |format|
        format.html #{ render 'show' }
        format.json { render :json => view_context.json_builder(@records, 'before') }
      end
    
    end
    
    def after
    
      @record = Rails.cache.fetch("document_#{params[:id]}", :expires_in => VirtualShelf.config.cache_timeout) do
        Record.find_by_document_number!(params[:id])
      end
      
      @records = Rails.cache.fetch("records_after_#{params[:id]}", :expires_in => VirtualShelf.config.cache_timeout) do
        Record.exclude_periodicals(session[:exclude_periodicals]).records_after(@record.call_number_sort,15).to_a
      end
      
      respond_to do |format|
        format.html #{ render 'show' }
        format.json { render :json => view_context.json_builder(@records, 'after') }
      end
    
    end
  end
end
