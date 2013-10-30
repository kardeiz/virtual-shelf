module VirtualShelf
  module RecordsHelper
  
    def link_class(document_number) 
      if session[:document_number] && session[:document_number] == document_number
        "current thumbnail"
      else "thumbnail" end
    end

    def cover_holder_class(format)
      case format
      when nil, "[ONLINE BOOK]"  
        "cover-holder no-cover cover-book-generic"
      when "[ONLINE JOURNAL]", "[PRINT JOURNAL]"
        "cover-holder no-cover cover-journal-generic"
      when "[AUDIO RECORDING]"
        "cover-holder no-cover cover-audio-generic"
      when "[MAP]"
        "cover-holder no-cover cover-map-generic"
      when "[VIDEO RECORDING]"
        "cover-holder no-cover cover-video-generic"
      when "[MICROFORM]", "[MUSICAL SCORE]"
        "cover-holder no-cover cover-file-generic"
      end
    end
  
  end
end
