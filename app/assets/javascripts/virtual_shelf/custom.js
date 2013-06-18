$(document).ready(function() {
  
  var do_it; $(window).on("resize", function() {
    clearTimeout(do_it);
    doit = setTimeout(function() { 
      $('.title-overlay').textfill({
        maxFontPixels: 12
      });
    }, 1000);
  });
  
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
			  position: { my: 'left center', at: 'right center', viewport: $(window) },
			  style: { classes: 'qtip-bootstrap' }
		  });		
    }); //end thumbnails
  }
  
  $.fn.checkGenericCovers = function() {
    var that = $(this);
    var ids = that.map(function(i,v) {
      var that = $(this);      
      var isbn = that.data('isbn') == null ? null : "ISBN:" + that.data('isbn');
      var oclc = that.data('oclc') == null ? null : "OCLC:" + that.data('oclc');      
      console.log(isbn);
      if (isbn || oclc) { return isbn || oclc; }
    }).get().join(',');
    
    var _uri = $('#virtual-shelf-root').data('root').replace(/\/$/,'');
    var uri = _uri + '/caching/google.json?ids=' + encodeURIComponent(ids);
    
    function googleResults(data) {
      that.each(function() {
        var that = $(this);      
        var isbn = that.data('isbn') == null ? null : "ISBN:" + that.data('isbn');
        var oclc = that.data('oclc') == null ? null : "OCLC:" + that.data('oclc');
        if (data[isbn] || data[oclc]) {
          var url = data[isbn] || data[oclc];
          var new_div = $('<div class="cover-holder has-cover"/>').css({
            backgroundImage: 'url(' + url + ')',
            backgroundSize: 'contain'
          });
          that.find('.no-cover-container').replaceWith(new_div);
        }
      });
    }
    
    var googleGet = $.get(uri)
    googleGet.done(googleResults);
  }
  
  $.fn.redoThumbnailsforIE = function () {
    if (!Modernizr.backgroundSize) {
      $(this).css("background-size", "contain");
    }
  }
  
  function onNewPageFunctions() { 
    $('.title-overlay').textfill({ maxFontPixels: 12 });
    $('.thumbnail').qTipLoader();
    $('.thumbnail:has(.no-cover-container)').checkGenericCovers();
    $('div.cover-holder').redoThumbnailsforIE();
  }
  
  $('body').on("click", '.arrow-left', function(e) {
    var href = $(this).attr("href");
    e.preventDefault();
    $.get(href + '.json', getNewPage('right', 'left'));
  });
  
  $('body').on("click", '.arrow-right', function(e) {
    var href = $(this).attr("href");
    e.preventDefault();
    $.get(href + '.json', getNewPage('left', 'right')); 
  });
  
  function _truncate(tstr) {  
    if (tstr.length > 50) {
      return $.trim(tstr.substring(0,47)) + "...";
    } else {
      return tstr;
    }  
  }
  
  function getNewPage(exit,enter) {
    return function(data) {  
      $('.arrow-left').attr("href",data.left_arrow_href);
      $('.arrow-right').attr("href",data.right_arrow_href);
      
      var prev_slide = $('div.slide');      
      var new_slide = $('<div class="slide hide"/>').css("position","absolute").appendTo('.thumbnails-div');      
      if (data.slide.thumbnails) {
        var ul = $('<ul class="thumbnails"/>').appendTo(new_slide);
        $.each(data.slide.thumbnails, function (i,v) {
          var li = $('<li class="span2"/>').appendTo(ul);
          var a = $('<a/>').attr({ 
            href: v.link_href,
            target: "_top"
          }).data(v.link_data).addClass(v.link_class).appendTo(li);
          if (v.cover_style) {
            $('<div class="cover-holder has-cover" style="' + v.cover_style + '"/>').appendTo(a);
          } else {
            var div = $('<div class="no-cover-container"/>').appendTo(a);
            var text = $('<span/>').html(_truncate(a.data('title')));
            $('<div/>').addClass(v.cover_class).appendTo(div);
            $('<div class="title-overlay"/>').append(text).appendTo(div);
          }
        });
      } else {
        new_slide.append('<p>' + data.slide + '</p>');
      }
            
      prev_slide.hide('slide', {direction: exit}, 1000, function() { prev_slide.remove(); });
      new_slide.show('slide', {direction: enter}, 1000, function() { new_slide.css("position","relative"); }); 
      
      onNewPageFunctions();
    };  
  }
  
  onNewPageFunctions();
  
});
