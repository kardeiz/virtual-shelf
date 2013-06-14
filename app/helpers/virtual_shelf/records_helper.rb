module VirtualShelf
  module RecordsHelper
  
    def json_builder(records, position)
    
      if records.empty?
        response = if position == 'before'
          { "left_arrow_href" => '#', "right_arrow_href" => url_for(:back) }
        elsif position == 'after'
          { "left_arrow_href" => url_for(:back), "right_arrow_href" => '#' }
        end
        return response.merge({"slide" => "There's nothing here."}).to_json
      end
      
      cover_array = records.map do |record|
        { 
          "link_class" => link_class(record.document_number),
          "link_href" => record.lib_link,
          "link_data" => record.hash_for_js,
          "cover_style" => (record.has_cover? ? record.cover_background_image : nil),
          "cover_class" => (record.has_cover? ? nil : cover_holder_class(record.format))
        }
      end
      { 
        "left_arrow_href" => before_record_path(@records.first.document_number),
        "right_arrow_href" => after_record_path(@records.last.document_number),
        "slide" => { "thumbnails" => cover_array }
      }.to_json
    end

    def link_class(document_number) 
      current = "current" if session[:document_number] && session[:document_number] == document_number
      ["thumbnail", current].compact.join(" ")
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
