$(function() {
   var accordionActive = false;
  
   $(window).on('resize', function() {
       var windowWidth = $(window).width();
       var $topMenu = $('#top-menu');
       var $sideMenu = $('#side-menu');     
       
       if (windowWidth < 768) {
          if ($topMenu.hasClass("active")) {             
            $topMenu.removeClass("active");
            $sideMenu.addClass("active");
            
            var $ddl = $('#top-menu .movable.dropdown');
            $ddl.detach();
            $ddl.removeClass('dropdown');
            $ddl.addClass('nav-header');
            
            $ddl.find('.dropdown-toggle').removeClass('dropdown-toggle').addClass('link');
            $ddl.find('.dropdown-menu').removeClass('dropdown-menu').addClass('submenu');
                        
            $ddl.prependTo($sideMenu.find('.accordion'));
            $('#top-menu #qform').detach().removeClass('navbar-form').prependTo($sideMenu);
            
            if (!accordionActive) {
               var Accordion2 = function(el, multiple) {
                 this.el = el || {};
                 this.multiple = multiple || false;

                  // Variables privadas
                 var links = this.el.find('.movable .link');
                 // Evento
                 links.on('click', {el: this.el, multiple: this.multiple}, this.dropdown);
                }

              Accordion2.prototype.dropdown = function(e) {
                var $el = e.data.el;
                $this = $(this),
                  $next = $this.next();

                $next.slideToggle();
                $this.parent().toggleClass('open');

                if (!e.data.multiple) {
                  $el.find('.movable .submenu').not($next).slideUp().parent().removeClass('open');
                };
              }    

              var accordion = new Accordion2($('ul.accordion'), false); 
              accordionActive = true;
            }
          }
       }
       else {
          if ($sideMenu.hasClass("active")) {              
            $sideMenu.removeClass('active');
            $topMenu.addClass('active');
            
            var $ddl = $('#side-menu .movable.nav-header');
            $ddl.detach();
            $ddl.removeClass('nav-header');
            $ddl.addClass('dropdown');
            
            $ddl.find('.link').removeClass('link').addClass('dropdown-toggle');
            $ddl.find('.submenu').removeClass('submenu').addClass('dropdown-menu');
            
             $('#side-menu #qform').detach().addClass('navbar-form').appendTo($topMenu.find('.nav'));
            $ddl.appendTo($topMenu.find('.nav'));
          }
       }
   });
  
  /**/
  var $menulink = $('.side-menu-link'),       
      $wrap = $('.wrap');
  
  $menulink.click(function() {    
    $menulink.toggleClass('active');
    $wrap.toggleClass('active');    
    return false;
  });
  
  /*Accordion*/
  var Accordion = function(el, multiple) {
    this.el = el || {};
    this.multiple = multiple || false;

    // Variables privadas
    var links = this.el.find('.link');
    // Evento
    links.on('click', {el: this.el, multiple: this.multiple}, this.dropdown);
  }

  Accordion.prototype.dropdown = function(e) {
     var $el = e.data.el;
     $this = $(this),
      $next = $this.next();

    $next.slideToggle();
    $this.parent().toggleClass('open');

    if (!e.data.multiple) {
      $el.find('.submenu').not($next).slideUp().parent().removeClass('open');
    };
  }    

  var accordion = new Accordion($('ul.accordion'), false); 
  
  
});

/**
 * Get the value of a querystring
 * @param  {String} field The field to get the value of
 * @param  {String} url   The URL to get the value from (optional)
 * @return {String}       The field value
 */
var getQueryString = function ( field, url ) {
    var href = url ? url : window.location.href;
    var reg = new RegExp( '[?&]' + field + '=([^&#]*)', 'i' );
    var string = reg.exec(href);
    return string ? string[1] : null;
};

$('#carriers #open-Update').click(function () {
    var row_index = $(this).parent().parent().parent().index() + 1;
    var c = document.getElementById('carriers');
    var gwid  =  $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
    var name  =  $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
    var ip_addr  =  $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
    var strip  =  $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
    var prefix  =  $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
    
   /** Clear out the modal */
    $(".modal-body #gwid").val();
    $(".modal-body #name").val();
    $(".modal-body #ip_addr").val();
    $(".modal-body #strip").val();
    $(".modal-body #prefix").val();
    
    $(".modal-body #gwid").val(gwid);
    $(".modal-body #name").val(name);
    $(".modal-body #ip_addr").val(ip_addr);
    $(".modal-body #strip").val(strip);
    $(".modal-body #prefix").val(prefix);
});

$('#carriers #open-Delete').click(function () {
    var row_index = $(this).parent().parent().parent().index() + 1;
    var c = document.getElementById('carriers');
    var gwid  =  $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
    var name  =  $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
    $(".modal-body #gwid").val(gwid);
    $(".modal-body #name").val(name);
});

$('#inboundmapping #open-Update').click(function () {
    var row_index = $(this).parent().parent().parent().index() + 1;
    var c = document.getElementById('inboundmapping');
    var ruleid  =  $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
    var prefix  =  $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
    var gwname  =  $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
    var gwid  =  $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();

    $(".modal-body #ruleid").val();
    $(".modal-body #prefix").val();
    $(".modal-body #gwid").val();
    $(".modal-body #ruleid").val(ruleid);
    $(".modal-body #prefix").val(prefix);
    $(".modal-body #gwid").val(gwid);

});

$('#inboundmapping #open-Delete').click(function () {
    var row_index = $(this).parent().parent().parent().index() + 1;
    var c = document.getElementById('inboundmapping');
    var ruleid  =  $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
    $(".modal-body #ruleid").val(ruleid);
});
