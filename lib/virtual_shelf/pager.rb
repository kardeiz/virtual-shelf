module VirtualShelf
  class Pager
  
    WINDOW  = 15
    PADDING = 52
    OFFSET  = 7
    ADDITIONAL = 60
    
    def c_opts
      @@opts ||= { :expires_in => VirtualShelf.config.cache_timeout }
    end
    
    def c_opts_force
      c_opts.merge(:force => true)
    end
    
    def c_keys
      { 
        :document => "document/#{@document_number}",
        :before   => "before/#{@e}/#{@page.abs}/#{@document_number}",
        :after    => "after/#{@e}/#{@page.abs}/#{@document_number}"
      }
    end
    
    def initialize(document_number, page, e)
      @document_number, @page, @e = document_number, page, e
    end
    
    def calc
      OFFSET + WINDOW * @page.abs
    end  
    
    def record
      @_record ||= Rails.cache.fetch(c_keys[:document], c_opts) do
        Record.find_by_document_number!(@document_number)       
      end
    end
    
    def records_before(_s, _w)
      @_records_before ||= Rails.cache.fetch(c_keys[:before], c_opts) do
        record.records_before(calc, @e).slice(_s, _w).reverse
      end
    end
    
    def records_after(_s, _w)
      @_records_after ||= Rails.cache.fetch(c_keys[:after], c_opts) do
        record.records_after(calc, @e).slice(_s, _w)
      end
    end
    
    def before?
      @page < 0
    end
    
    def after?
      @page > 0
    end
    
    def records_for_page
      if before? then records_before(calc - WINDOW, WINDOW)
      elsif after? then records_after(calc - WINDOW, WINDOW)
      else records_before(0, OFFSET) + [record] + records_after(0, OFFSET)
      end
    end
    
#    def check_if_more_records_needed
#      get_more_records_before if before? && calc > records_before.size
#      get_more_records_after if after? && calc > records_after.size
#    end
#    
#    
#    
#    def get_more_records_before
#      more = records_before.first.records_before(ADDITIONAL + calc, @e)
#      all = more.concat(records_before)
#      records_after = Rails.cache.fetch(c_keys[:before], c_opts_force) do
#        all
#      end
#    end
#    
#    def get_more_records_after
#      more = records_after.last.records_after(ADDITIONAL + calc, @e)
#      all = records_after.concat(more)
#      records_after = Rails.cache.fetch(c_keys[:after], c_opts_force) do
#        all
#      end
#    end    
    
  end
end
