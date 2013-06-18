(function(){

  if (!window.jQuery) {
    
    var head_tag = document.getElementsByTagName("head")[0];
    
    var jquery_script = document.createElement('script');
    jquery_script.type = 'text/javascript';
    jquery_script.src = '//cdnjs.cloudflare.com/ajax/libs/jquery/1.8.3/jquery.min.js';    
    head_tag.appendChild(jquery_script);
    checkJquery();
  } 
  else {
    jQueryCode(jQuery);
  }

  /* I don't like ie8 */
  function checkJquery() {
    if (window.jQuery) {
      jQueryCode(jQuery);
    } else {
      window.setTimeout(checkJquery, 50);
    }
  }
  
  function jQueryCode($) { 
    
    var jquery_ui_css = $('<link/>').attr({
      rel: 'stylesheet', 
      href: '//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.10.0/css/smoothness/jquery-ui-1.10.0.custom.min.css'
    });
    
    $('head').append(jquery_ui_css);
    $.getScript("//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.10.0/jquery-ui.min.js", createModal);

    function createModal() {
      
      $('body').on("click", "a.virtual-shelf", function(e) {
        e.preventDefault();
        loadIframe( $(this) );
      });

      function loadIframe(that) {
        
        var iframe_src = that.attr("href");
          
        var iframe = $('<iframe/>').css({ 
          width: "100%", 
          height: "100%",
          boxSizing: "border-box"
        }); 
      
        var modal_div = $('<div/>').attr("class","modal-content").css("overflow","hidden").append(iframe);       
        $('body').append(modal_div);
                
        $(function() {
          modal_div.dialog({
            width: $(window).width() < 1200 ? $(window).width() - 100 : 1200,
            height: $(window).height() < 768 ? $(window).height() - 100 : 768,
            title: "Virtual Browse",
            autoOpen: false,
            modal: true,
            close: function( event, ui ) {
              $(this).remove();
            }
          });
        });
        
        modal_div.find('iframe').attr({ 
          src: iframe_src
        });
        
        modal_div.dialog('open');
      }
    }
  }
})();

