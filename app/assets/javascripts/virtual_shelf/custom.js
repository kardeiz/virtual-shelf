$(document).ready(function() {
  
  var root = $('#virtual-shelf-root').data('root');
  $(':checkbox').on('change', function () {
    $(this).closest('form').submit();
  });

  $.fn.qTipLoader = function() {
    $(this).each(function() {
      var that = $(this);     		
      var qtc = $('<div class="qtip-content-div"></div>');   
      qtc.append($.map([ 
        that.data('title-with-format'),
        that.data('call-number'),
        that.data('date'),
        that.data('summary'),
        that.data('contents') 
      ], function(v,i) {
        if (v) { return '<p>' + v + '</p>'; }
      }).join('<hr/>'));
      
      that.qtip({
        content: qtc.html(),
			  position: { 
			    my: 'left center', at: 'right center', viewport: $(window)
			  },
			  style: { classes: 'qtip-bootstrap' }
		  });		
    });
  }
  
  $.fn.checkGenericCovers = function() {
    var with_ids = [];
    var ids = $(this).map(function() {
      var that = $(this);      
      var isbn = that.data('isbn') == null ? null : "ISBN:" + that.data('isbn');
      var oclc = that.data('oclc') == null ? null : "OCLC:" + that.data('oclc');  
      if (isbn || oclc) { 
        with_ids.push(that);
        return isbn || oclc;
      }
    }).get();
    var books_url = root + 'caching/books.json?ids=' + encodeURIComponent(ids.join(','));
    $.get(books_url, googleResults)
    
    function googleResults(data) {
      $.each(ids, function(i, o) {
        if (data[o]) {
          var thumb_url = root + 'caching/thumbnails?url=' + encodeURIComponent(data[o]);
          var new_div = $('<div class="cover-holder has-cover"/>').css({
            backgroundImage: 'url(' + thumb_url + ')', backgroundSize: 'contain'
          });
          with_ids[i].find('.no-cover-container').replaceWith(new_div);
        }
      });
    }
  }
  
  $.fn.redoThumbnailsforIE = function () {
    if (!Modernizr.backgroundSize) { 
      $(this).css("background-size", "contain");
    }
  }  
  function onPageLoadRun() { 
    $('.title-overlay').textfill({ maxFontPixels: 12 });
    $('.thumbnail').qTipLoader();
    $('div.cover-holder').redoThumbnailsforIE();
    $('.thumbnail:has(.no-cover-container)').checkGenericCovers();    
  }
    
  $('body').on("click", '.arrow-left', function(e) {
    e.preventDefault();
    $.get( $('.arrow-left').attr('href') + '?js=true', getNewPage('right', 'left'));
  });
  
  $('body').on("click", '.arrow-right', function(e) {
    e.preventDefault();
    $.get( $('.arrow-right').attr('href') + '?js=true', getNewPage('left', 'right'));
  });
  
  function getNewPage(exit,enter) {
    return function(_data) {
      var data = $(_data);
      $('.arrow-left').attr("href", data.find('.arrow-left').attr("href") );
      $('.arrow-right').attr("href", data.find('.arrow-right').attr("href") );
      var prev_slide = $('div.slide');      
      var new_slide = data.find('.slide')
        .css("position","absolute").addClass('hide')
        .appendTo('.thumbnails-div');
      prev_slide.hide('slide', {direction: exit}, 1000, function() {
        prev_slide.remove();
      });
      new_slide.show('slide', {direction: enter}, 1000, function() {
        new_slide.css("position","relative");
      });      
      onPageLoadRun();
    }
  }  
  onPageLoadRun();  
});
