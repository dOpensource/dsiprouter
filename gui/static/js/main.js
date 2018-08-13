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
          };

          Accordion2.prototype.dropdown = function(e) {
            var $el = e.data.el;
            $this = $(this);
            $next = $this.next();

            $next.slideToggle();
            $this.parent().toggleClass('open');

            if (!e.data.multiple) {
              $el.find('.movable .submenu').not($next).slideUp().parent().removeClass('open');
            }
          };

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
  };

  Accordion.prototype.dropdown = function(e) {
    var $el = e.data.el;
    $this = $(this),
      $next = $this.next();

    $next.slideToggle();
    $this.parent().toggleClass('open');

    if (!e.data.multiple) {
      $el.find('.submenu').not($next).slideUp().parent().removeClass('open');
    }
  };

  var accordion = new Accordion($('ul.accordion'), false);
});


$(function() {
  $('a').each(function() {
    if ($(this).prop('href') === window.location.href) {
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
var getQueryString = function(field, url) {
  var href = url ? url : window.location.href;
  var reg = new RegExp('[?&]' + field + '=([^&#]*)', 'i');
  var string = reg.exec(href);
  return string ? string[1] : null;
};

$('#open-PbxAdd').click(function() {
  /** Clear out the modal */
  var modal_body = $('#add .modal-body');
  modal_body.find(".gwid").val('');
  modal_body.find(".name").val('');
  modal_body.find(".ip_addr").val('');
  modal_body.find(".strip").val('');
  modal_body.find(".prefix").val('');
  modal_body.find(".fusionpbx_db_server").val('');
  modal_body.find(".fusionpbx_db_username").val('');
  modal_body.find(".fusionpbx_db_password").val('');
  modal_body.find(".authtype").val('');
  modal_body.find(".auth_username").val('');
  modal_body.find(".auth_password").val('');
  modal_body.find(".auth_domain").val('');
  modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('off');

  /* make sure ip_addr not disabled */
  modal_body.find('.ip_addr').prop('disabled', false);
});


$('#pbxs #open-Update').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('pbxs');
  var gwid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
  var name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
  var ip_addr = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
  var strip = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
  var prefix = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
  var fusionpbxenabled = $(c).find('tr:eq(' + row_index + ') td:eq(6)').text();
  var fusionpbx_db_server = $(c).find('tr:eq(' + row_index + ') td:eq(7)').text();
  var fusionpbx_db_username = $(c).find('tr:eq(' + row_index + ') td:eq(8)').text();
  var fusionpbx_db_password = $(c).find('tr:eq(' + row_index + ') td:eq(9)').text();
  var authtype = $(c).find('tr:eq(' + row_index + ') td:eq(10)').text();
  var auth_username = $(c).find('tr:eq(' + row_index + ') td:eq(11)').text();
  var auth_password = $(c).find('tr:eq(' + row_index + ') td:eq(12)').text();
  var auth_domain = $(c).find('tr:eq(' + row_index + ') td:eq(13)').text();


  /** Clear out the modal */
  var modal_body = $('#edit .modal-body');
  modal_body.find(".gwid").val('');
  modal_body.find(".name").val('');
  modal_body.find(".ip_addr").val('');
  modal_body.find(".strip").val('');
  modal_body.find(".prefix").val('');
  modal_body.find(".authtype").val('');
  modal_body.find(".auth_username").val('');
  modal_body.find(".auth_password").val('');
  modal_body.find(".auth_domain").val('');

  /* update modal fields */
  modal_body.find(".gwid").val(gwid);
  modal_body.find(".name").val(name);
  modal_body.find(".ip_addr").val(ip_addr);
  modal_body.find(".strip").val(strip);
  modal_body.find(".prefix").val(prefix);
  modal_body.find(".authtype").val(authtype);
  modal_body.find(".fusionpbx_db_server").val(fusionpbx_db_server);
  modal_body.find(".fusionpbx_db_username").val(fusionpbx_db_username);
  modal_body.find(".fusionpbx_db_password").val(fusionpbx_db_password);
  modal_body.find(".auth_username").val(auth_username);
  modal_body.find(".auth_password").val(auth_password);
  modal_body.find(".auth_domain").val(auth_domain);

  if (fusionpbxenabled === "Yes") {
    modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('on');
    modal_body.find('.FusionPBXDomainOptions').removeClass("hidden");
  }
  else {
    modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('off');
  }

  if (authtype !== "") {
    /* userpwd auth enabled, Set the radio button to true */
    modal_body.find('.authtype[data-toggle="userpwd_enabled"]').trigger('click');
    modal_body.find('.ip_addr').prop('disabled', true);
  }
  else {
    /* ip auth enabled, Set the radio button to true */
    modal_body.find('.authtype[data-toggle="ip_enabled"]').trigger('click');
    modal_body.find('.ip_addr').prop('disabled', false);
  }
});

$('#pbxs #open-Delete').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('pbxs');
  var gwid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
  var name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();

  /* update modal fields */
  var modal_body = $('#delete .modal-body');
  modal_body.find(".gwid").val(gwid);
  modal_body.find(".name").val(name);
});

$('#inboundmapping #open-Update').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('inboundmapping');
  var ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
  var prefix = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
  var gwname = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
  var gwid = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();

  /** Clear out the modal */
  var modal_body = $('#edit .modal-body');
  modal_body.find(".ruleid").val('');
  modal_body.find(".prefix").val('');
  modal_body.find(".gwid").val('');

  /* update modal fields */
  modal_body.find(".ruleid").val(ruleid);
  modal_body.find(".prefix").val(prefix);
  modal_body.find(".gwid").val(gwid);
});

$('#inboundmapping #open-Delete').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('inboundmapping');
  var ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();

  /* update modal fields */
  var modal_body = $('#delete .modal-body');
  modal_body.find(".ruleid").val(ruleid);
});

$('#outboundmapping #open-Update').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('outboundmapping');

  var ruleid = $(c).find('tr:eq(' + row_index + ') > td.ruleid').text();
  var groupid = $(c).find('tr:eq(' + row_index + ') > td.groupid').text();
  var prefix = $(c).find('tr:eq(' + row_index + ') > td.prefix').text();
  var from_prefix = $(c).find('tr:eq(' + row_index + ') > td.from_prefix').text();
  var timerec = $(c).find('tr:eq(' + row_index + ') > td.timerec').text();
  var priority = $(c).find('tr:eq(' + row_index + ') > td.priority').text();
  var routeid = $(c).find('tr:eq(' + row_index + ') > td.routeid').text();
  var gwlist = $(c).find('tr:eq(' + row_index + ') > td.gwlist').text();
  var name = $(c).find('tr:eq(' + row_index + ') > td.description').text();

  /** Clear out the modal */
  var modal_body = $('#edit .modal-body');
  modal_body.find(".ruleid").val('');
  modal_body.find(".groupid").val('');
  modal_body.find(".prefix").val('');
  modal_body.find(".from_prefix").val('');
  modal_body.find(".timerec").val('');
  modal_body.find(".priority").val('');
  modal_body.find(".routeid").val('');
  modal_body.find(".gwlist").val('');
  modal_body.find(".name").val('');

  /* update modal fields */
  modal_body.find(".ruleid").val(ruleid);
  modal_body.find(".groupid").val(groupid);
  modal_body.find(".prefix").val(prefix);
  modal_body.find(".from_prefix").val(from_prefix);
  modal_body.find(".timerec").val(timerec);
  modal_body.find(".priority").val(priority);
  modal_body.find(".routeid").val(routeid);
  modal_body.find(".gwlist").val(gwlist);
  modal_body.find(".name").val(name);
});

$('#outboundmapping #open-Delete').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('outboundmapping');
  var ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();

  /* update modal fields */
  var modal_body = $('#delete .modal-body');
  modal_body.find(".ruleid").val(ruleid);
  modal_body.find(".ruleid").val(ruleid);
});

function reloadkam(elmnt) {
  //elmnt.style.backgroundColor = "red";
  //elmnt.style.borderColor = "red"
  var msg_bar = $(".message-bar");
  var reload_button = $('#reloadkam');


  $.ajax({
    type: "GET",
    url: "/reloadkam",
    dataType: "json",
    success: function(msg) {
      if (msg.status === 1) {
        msg_bar.addClass("alert alert-success");
        msg_bar.html("<strong>Success!</strong> Kamailio was reloaded successfully!");
        reload_button.removeClass('btn-warning');
        reload_button.addClass('btn-primary');
      }
      else {
        msg_bar.addClass("alert alert-danger");
        msg_bar.html("<strong>Failed!</strong> Kamailio was NOT reloaded successfully!");
      }

      msg_bar.show();
      msg_bar.slideUp(3000, "linear");
      //elmnt.style.backgroundColor = "#337ab7";
      //elmnt.style.borderColor = "#2e6da4";
    }
  });
}

/* listener for fusionPBX toggle */
$('.modal-body .toggleFusionPBXDomain').change(function() {
  var modal = $(this).closest('div.modal');
  var modal_body = modal.find('.modal-body');

  var ip_addr = modal_body.find('input.ip_addr').val();
  var fusionpbx_db_server = modal_body.find('.fusionpbx_db_server').val();
  var fusionpbx_db_username = modal_body.find('.fusionpbx_db_username').val();

  if ($(this).is(":checked") || $(this).prop("checked")) {
    modal_body.find('.FusionPBXDomainOptions').removeClass("hidden");
    modal_body.find('.fusionpbx_db_enabled').val(1);

    /* event triggered within edit modal */
    if (modal.attr('id').toLowerCase().indexOf('edit') > -1) {
      if (fusionpbx_db_server === "" && fusionpbx_db_username === "") {
        modal_body.find('.fusionpbx_db_server').val(ip_addr);
        modal_body.find('.fusionpbx_db_username').val('fusionpbx');
      }
    }
  }

  else {
    modal_body.find('.FusionPBXDomainOptions').addClass("hidden");
    modal_body.find('.fusionpbx_db_enabled').val(0);
  }
});

/* listener for teleblock toggle */
$('#toggleTeleblock').change(function() {
  if ($(this).is(":checked") || $(this).prop("checked")) {
    $('#teleblockOptions').removeClass("hidden");
    $(this).val("1");
    $(this).bootstrapToggle('on');
  }
  else {
    $('#teleblockOptions').addClass("hidden");
    $(this).val("0");
    $(this).bootstrapToggle('off');
  }
});

/* listener for authtype radio buttons */
$('.authoptions.radio').get().forEach(function(elem) {
  elem.addEventListener('click', function(e) {
    var target_radio = $(e.target);
    /* fix target if we hit an ancestor elem containing it */
    if ($(e.target).get(0).nodeName.toLowerCase() !== "input") {
      target_radio = target_radio.find('input[type="radio"]');
    }
    var auth_radios = $(e.currentTarget).find('input[type="radio"]');
    var modal_body = $(this).closest('.modal-body');
    var hide_show_ids = [];
    $.each(auth_radios, function() {
      hide_show_ids.push('#' + $(this).data('toggle'));
    });
    var hide_show_divs = modal_body.find(hide_show_ids.join(', '));

    if (target_radio.is(":checked")) {
      $.each(hide_show_divs, function(i, elem) {
        if (target_radio.data('toggle') === $(elem).attr('name')) {
          $(elem).removeClass("hidden");
        }
        else {
          $(elem).addClass("hidden");
        }
      });
    }
    else {
      $.each(hide_show_divs, function(i, elem) {
        if (target_radio.data('toggle') === $(elem).attr('name')) {
          $(elem).addClass("hidden");
        }
        else {
          $(elem).removeClass("hidden");
        }
      });
    }
    /* trickle down DOM tree */
  }, true);
});

/* handle multiple modal stacking */
$(window).on('show.bs.modal', function(e) {
  modal = $(e.target);
  zIndexTop = Math.max.apply(null, $('.modal').map(function() {
    var z = parseInt($(this).css('z-index'));
    return isNaN(z, 10) ? 0 : z;
  }));
  modal.css('z-index', zIndexTop + 10);
  modal.addClass('modal-open');
});
$(window).on('hide.bs.modal', function(e) {
  modal = $(e.target);
  modal.css('z-index', '1050');
});

/* remove non-printable ascii chars on paste */
$('form input[type!="hidden"]').on("paste", function() {
  $(this).val(this.value.replace(/[^\x20-\x7E]+/g, ''))
});

/* make sure autofocus is honored on loaded modals */
$('.modal').on('shown.bs.modal', function() {
  $(this).find('[autofocus]').focus();
});

