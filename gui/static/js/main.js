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
      $(this).removeClass('navlink');
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

/**
 * Disable / Re-enable a form submittable element
 * Use this instead of the HTML5 disabled prop
 * @param selector  String|jQuery Object    The selector for elem
 * @param disable   Boolean   Whether to disable or re-enable
 */
function toggleElemDisabled(selector, disable) {
  var select_elem = null;
  if (typeof selector === 'string' || selector instanceof String) {
    select_elem = $(selector);
  }
  else if (selector instanceof jQuery) {
    select_elem = selector;
  }
  else {
    console.err("toggleElemDisabled(): invalid selector argument");
    return;
  }
  if (disable) {
    select_elem.parent().css({
      'cursor': 'not-allowed'
    });
    select_elem.css({
      'background-color': '#EEEEEE',
      'opacity': '0.7',
      'pointer-events': 'none'
    });
    select_elem.prop('readonly', true);
    select_elem.prop('tabindex', -1);
  }
  else {
    select_elem.parent().removeAttr('style');
    select_elem.removeAttr('style');
    select_elem.prop('readonly', false);
    select_elem.prop('tabindex', 0);
  }
}

/**
 * Recursively search DOM tree until test is true
 * Starts at and includes selected node, tests each desc
 * Note that test callback applies to jQuery objects throughout
 * @param selector   String|jQuery Object  The selector for start node
 * @param test       function()            Test to apply to each node
 * @return           jQuery Object|null    Returns found node or null
 */
function descendingSearch(selector, test) {
  var select_node = null;
  if (typeof selector === 'string' || selector instanceof String) {
    select_node = $(selector);
  }
  else if (selector instanceof jQuery) {
    select_node = selector;
  }
  else {
    return null;
  }

  var num_nodes = select_node.length || 0;
  if (num_nodes > 1) {
    for (var i = 0; i < num_nodes; i++) {
        if (test(select_node[i])) {
          return select_node[i];
      }
    }
  }
  else {
    if (test(select_node)) {
        return select_node;
      }
  }

  node_list = select_node.children();
  if (node_list.length <= 0) {
    return null;
  }

  descendingSearch(node_list, test)
}

$('#open-CarrierAdd').click(function() {
  var modal = $('#add');
  modal.css('z-index','1070');
});

$('#open-PbxAdd').click(function() {
  /** Clear out the modal */
  var modal_body = $('#add .modal-body');
  modal_body.find(".gwid").val('');
  modal_body.find(".name").val('');
  modal_body.find(".ip_addr").val('');
  modal_body.find(".strip").val('');
  modal_body.find(".prefix").val('');
  modal_body.find(".fusionpbx_db_server").val('');
  modal_body.find(".fusionpbx_db_username").val('fusionpbx');
  modal_body.find(".fusionpbx_db_password").val('');
  modal_body.find(".authtype").val('ip');
  modal_body.find(".auth_username").val('');
  modal_body.find(".auth_password").val('');
  modal_body.find(".auth_domain").val('');
  modal_body.find('.FusionPBXDomainOptions').addClass("hidden");

  /* make sure ip_addr not disabled */
  toggleElemDisabled(modal_body.find('.ip_addr'), false);
});


$('#pbxs #open-Update').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('pbxs');
  var gwid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
  var name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
  var ip_addr = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
  var strip = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
  var prefix = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
  var fusionpbx_enabled = parseInt($(c).find('tr:eq(' + row_index + ') td:eq(7)').text(), 10);
  var fusionpbx_db_server = $(c).find('tr:eq(' + row_index + ') td:eq(8)').text();
  var fusionpbx_db_username = $(c).find('tr:eq(' + row_index + ') td:eq(9)').text();
  var fusionpbx_db_password = $(c).find('tr:eq(' + row_index + ') td:eq(10)').text();
  var authtype = $(c).find('tr:eq(' + row_index + ') td:eq(11)').text();
  var auth_username = $(c).find('tr:eq(' + row_index + ') td:eq(12)').text();
  var auth_password = $(c).find('tr:eq(' + row_index + ') td:eq(13)').text();
  var auth_domain = $(c).find('tr:eq(' + row_index + ') td:eq(14)').text();


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

  if (fusionpbx_enabled) {
      modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('on');
	  //modal_body.find('.FusionPBXDomainOptions').removeClass("hidden");
  }
  else {
      modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('off');
	  //modal_body.find('.FusionPBXDomainOptions').addClass("hidden");
  }


  if (authtype !== "") {
    /* userpwd auth enabled, Set the radio button to true */
    modal_body.find('.authtype[data-toggle="userpwd_enabled"]').trigger('click');
  }
  else {
    /* ip auth enabled, Set the radio button to true */
    modal_body.find('.authtype[data-toggle="ip_enabled"]').trigger('click');
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

$('#domains #open-Update').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('domains');
  var domain_id = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
  var domain_name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
  var domain_type = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
  var pbx_name = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
  var authtype = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
  var pbx_list = $(c).find('tr:eq(' + row_index + ') td:eq(6)').text();
  var notes = $(c).find('tr:eq(' + row_index + ') td:eq(7)').text();


  /** Clear out the modal */
  var modal_body = $('#edit .modal-body');
  modal_body.find(".domain_id").val('');
  modal_body.find(".domain_name").val('');
  modal_body.find(".domain_type").val('');
  modal_body.find(".pbx_name").val('');
  modal_body.find(".pbx_list").val('');
  modal_body.find(".notes").val('');

  /* update modal fields */
  modal_body.find(".domain_id").val(domain_id);
  modal_body.find(".domain_name").val(domain_name);
  modal_body.find(".domain_type").val(domain_type);
  modal_body.find(".pbx_name").val(pbx_name);
  modal_body.find(".pbx_list").val(pbx_list);
  modal_body.find(".notes").val(notes);

  if (authtype !== "") {
    /* Set the radio button if authtype is given */
    modal_body.find('.authtype[data-toggle="' + authtype + '"]').trigger('click');
  }
});

$('#domains #open-Delete').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('domains');
  var domain_id = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
  var domain_name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();

  /* update modal fields */
  var modal_body = $('#delete .modal-body');
  modal_body.find(".domain_id").val(domain_id);
  modal_body.find(".domain_name").val(domain_name);
});

$('#inboundmapping #open-Update').click(function() {
  var row_index = $(this).parent().parent().parent().index() + 1;
  var c = document.getElementById('inboundmapping');
  /* we only want the TEXT nodes value w/o other inline tags */
  var ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
  var prefix = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
  // var gwname = $(c).find('tr:eq(' + row_index + ') td:eq(3)').contents().filter(function() {
  //   return this.nodeType === Node.TEXT_NODE;
  // }).text();
  var notes = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
  var gwlist = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();

  /* we only support 2 pbx's so format accordingly */
  gwlist_arr = gwlist.replace(/(^\s+|\s+$)/g,'').split(',');
  gwid = gwlist_arr.length > 0 ? gwlist_arr[0] : '';
  alt_gwid = gwlist_arr.length > 1 ? gwlist_arr[1] : '';

  /** Clear out the modal */
  var modal_body = $('#edit .modal-body');
  modal_body.find(".ruleid").val('');
  modal_body.find(".prefix").val('');
  modal_body.find(".notes").val('');
  modal_body.find(".gwid").val('');
  modal_body.find(".alt_gwid").val('');

  /* update modal fields */
  modal_body.find(".ruleid").val(ruleid);
  modal_body.find(".prefix").val(prefix);
  modal_body.find(".notes").val(notes);
  modal_body.find("input.gwid").val(gwid);
  modal_body.find("input.alt_gwid").val(alt_gwid);

  /* update options selected */
  var selects = modal_body.find("select").get();
  for (var i = 0; i < selects.length; i++) {
    var options = $(selects[i]).find("option").get();
    for (var j = 0; j < options.length; j++) {
      if (gwlist_arr[i] === options[j].value) {
        $(options[j]).attr('selected', true);
        break;
      }
    }
  }
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

  if ($(this).is(":checked") || $(this).prop("checked")) {
    modal_body.find('.FusionPBXDomainOptions').removeClass("hidden");
    modal_body.find('.fusionpbx_db_enabled').val(1);

    /* uncheck other toggles */
    //modal_body.find(".toggleFreePBXDomain").bootstrapToggle('off');
  }

  else {
    modal_body.find('.FusionPBXDomainOptions').addClass("hidden");
    modal_body.find('.fusionpbx_db_enabled').val(0);
  }
});

/* listener for freePBX toggle */
$('.modal-body .toggleFreePBXDomain').change(function() {
  var modal = $(this).closest('div.modal');
  var modal_body = modal.find('.modal-body');

  if ($(this).is(":checked") || $(this).prop("checked")) {
    modal_body.find('.FreePBXDomainOptions').removeClass("hidden");
    modal_body.find('.freepbx_enabled').val(1);

    /* uncheck other toggles */
    modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('off');
  }

  else {
    modal_body.find('.FreePBXDomainOptions').addClass("hidden");
    modal_body.find('.freepbx_enabled').val(0);
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
    /* keep descending down DOM tree until input hit */
    target_radio = descendingSearch($(e.target), function(node) {
      return node.get(0).nodeName.toLowerCase() === "input"
    });
    if (target_radio === null) {
      return false;
    }
    var auth_radios = $(e.currentTarget).find('input[type="radio"]');
    var modal_body = $(this).closest('.modal-body');
    var hide_show_ids = [];
    $.each(auth_radios, function() {
      hide_show_ids.push('#' + $(this).data('toggle'));
    });
    var hide_show_divs = modal_body.find(hide_show_ids.join(', '));

    if (target_radio.is(":checked") || target_radio.prop("checked")) {
      /* enable ip_addr on ip auth in #edit modal only */
      if ($(this).closest('div.modal').attr('id').toLowerCase().indexOf('edit') > -1) {
        if (target_radio.data('toggle') === "ip_enabled") {
          toggleElemDisabled(modal_body.find('input.ip_addr'), false);
        }
        else {
          toggleElemDisabled(modal_body.find('input.ip_addr'), true);
        }
      }

      /* change value of authtype inputs */
      modal_body.find('.authtype').val(target_radio.data('toggle').split('_')[0]);

      /* show correct div's */
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
      /* change value of authtype inputs */
      modal_body.find('.authtype').val('');

      /* show correct div's */

      $.each(hide_show_divs, function(i, elem) {
        if (target_radio.data('toggle') === $(elem).attr('name')) {
          $(elem).addClass("hidden");
        }
        else {
          $(elem).removeClass("hidden");
        }
      });
    }
    /* trickle down DOM tree (capture event) */
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

