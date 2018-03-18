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


$(function(){
  $('a').each(function() {
    if ($(this).prop('href') == window.location.href) {
      $(this).addClass('currentlink');
    }
  });
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

$('#open-CarrierAdd').click(function () {

 /** Clear out the modal */
    $(".modal-body #gwid").val('');
    $(".modal-body #name").val('');
    $(".modal-body #ip_addr").val('');
    $(".modal-body #strip").val('');
    $(".modal-body #prefix").val('');
    $(".modal-body #authtype").val('');
    $(".modal-body #fusionpbx_db_server").val('');
    $(".modal-body #fusionpbx_db_username").val('');
    $(".modal-body #fusionpbx_db_password").val('');
    $(".modal-body #toggleFusionPBXDomainAdd").bootstrapToggle('off');
});


$('#carriers #open-Update').click(function () {
    var row_index = $(this).parent().parent().parent().index() + 1;
    var c = document.getElementById('carriers');
    var gwid  =  $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
    var name  =  $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
    var ip_addr  =  $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
    var strip  =  $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
    var prefix  =  $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
    var fusionpbxenabled  =  $(c).find('tr:eq(' + row_index + ') td:eq(6)').text();
    var fusionpbx_db_server  =  $(c).find('tr:eq(' + row_index + ') td:eq(7)').text();
    var fusionpbx_db_username  =  $(c).find('tr:eq(' + row_index + ') td:eq(8)').text();
    var fusionpbx_db_password  =  $(c).find('tr:eq(' + row_index + ') td:eq(9)').text();
    var authtype  =  $(c).find('tr:eq(' + row_index + ') td:eq(10)').text();
    var pbx_username  =  $(c).find('tr:eq(' + row_index + ') td:eq(11)').text();
    var pbx_password  =  $(c).find('tr:eq(' + row_index + ') td:eq(12)').text();
     


   /** Clear out the modal */
    $(".modal-body #gwid").val('');
    $(".modal-body #name").val('');
    $(".modal-body #ip_addr").val('');
    $(".modal-body #strip").val('');
    $(".modal-body #prefix").val('');
    $(".modal-body #pbx_username").val('');
    $(".modal-body #pbx_password").val('');
     
    $(".modal-body #gwid").val(gwid);
    $(".modal-body #name").val(name);
    $(".modal-body #ip_addr").val(ip_addr);
    $(".modal-body #strip").val(strip);
    $(".modal-body #prefix").val(prefix);
    $(".modal-body #fusionpbx_db_server").val(fusionpbx_db_server);
    $(".modal-body #fusionpbx_db_username").val(fusionpbx_db_username);
    $(".modal-body #fusionpbx_db_password").val(fusionpbx_db_password);
    $(".modal-body #pbx_username").val(pbx_username);
    $(".modal-body #pbx_password").val(pbx_password);

    if (fusionpbxenabled == "Yes") {
    	$(".modal-body #toggleFusionPBXDomain").bootstrapToggle('on');
    	$('#FusionPBXDomainOptions').removeClass("hidden");
    }
    else {
     
	 $(".modal-body #toggleFusionPBXDomain").bootstrapToggle('off');

    }

    if (authtype != "") {
	
	//Set the radio button to true
	$("div #authtype_4").prop("checked",true );
	$('#userpwd_enabled2').removeClass("hidden");
    }
    else {  //IP auth is enabled

	//Set the radio button to true
	$("div #authtype_3").prop("checked",true );
	$('#userpwd_enabled2').addClass("hidden");
    }

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

$('#toggleFusionPBXDomain').change(function() {
	if ($(this).is(":checked")) {
		$('#FusionPBXDomainOptions').removeClass("hidden");
		$('.modal-body #fusionpbx_db_enabled').val(1);
		$('.modal-body #fusionpbx_db_enabled').val(1);
        
	}
	else {
		$('#FusionPBXDomainOptions').addClass("hidden");
		$('.modal-body #fusionpbx_db_enabled').val(0);

	}
	
});

$('#toggleFusionPBXDomainAdd').change(function() {
	if ($(this).is(":checked")) {
		$('#FusionPBXDomainOptionsAdd').removeClass("hidden");
		$('.modal-body #fusionpbx_db_enabled').val(1);
        
        if ($(".modal-body #fusionpbx_db_server").val() == "" &&  $(".modal-body #fusionpbx_db_username").val() == "") {
            var ip_addr = $("input#ip_addr").val();
            $(".modal-body #fusionpbx_db_server").val(ip_addr);
            $(".modal-body #fusionpbx_db_username").val("fusionpbx");
	    }
    
    }
	else {
		$('#FusionPBXDomainOptionsAdd').addClass("hidden");
		$('.modal-body #fusionpbx_db_enabled').val(0);

	}
	
});

$('#authoptions').change(function() {


	// authtype_2 is the username/password option

	if ($("div #authtype_2").is(":checked") ) {
		$('#userpwd_enabled').removeClass("hidden");
		$('#userpwd_enabled').prop("hidden",false);		
	}
	else {

		$('#userpwd_enabled').addClass("hidden");
		$('#userpwd_enabled').prop("hidden",true);
		
	}


});

$('#authoptions2').change(function() {


	// authtype_2 is the username/password option

	if ($("div #authtype_4").is(":checked") ) {
		$('#userpwd_enabled2').removeClass("hidden");
		$('#userpwd_enabled2').prop("hidden",false);		
	}
	else {

		$('#userpwd_enabled2').addClass("hidden");
		$('#userpwd_enabled2').prop("hidden",true);
		
	}


});


function reloadkam(elmnt) {

	//elmnt.style.backgroundColor = "red";
	//elmnt.style.borderColor = "red"

	$.ajax({
   		type: "GET",
   		url: "/reloadkam",
		dataType: "json",
   		success: function(msg){
			if (msg.status == 1) {
				$(".message-bar").addClass("alert alert-success");
				$(".message-bar").html("<strong>Success!</strong> Kamailio was reloaded successfully!");
			}
			else {
				$(".message-bar").addClass("alert alert-danger");
				$(".message-bar").html("<strong>Failed!</strong> Kamailio was NOT reloaded successfully!");
			}

			$(".message-bar").show();
			$(".message-bar").slideUp(3000,"linear");
			//elmnt.style.backgroundColor = "#337ab7";
        		//elmnt.style.borderColor = "#2e6da4";
  		 }
 	});

}


$('#toggleTeleblock').change(function() {
	 if ($(this).is(":checked")) {
		   $('#teleblockOptions').removeClass("hidden");
		   $('#toggleTeleblock').val("1");
		   $('#toggleTeleblock').bootstrapToggle('on');;
		         
		  }
	 else {
		   $('#teleblockOptions').addClass("hidden");
		   $('#toggleTeleblock').val("0");
		   $('#toggleTeleblock').bootstrapToggle('off');

		  }
	 
});
