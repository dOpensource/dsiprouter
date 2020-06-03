/* TODO: decouple scope like other js scripts */

// throw an error if required functions not defined
if (typeof showNotification === "undefined") {
  throw new Error("showNotification() is required and is not defined");
}
if (typeof descendingSearch === "undefined") {
  throw new Error("descendingSearch() is required and is not defined");
}
if (typeof toggleElemDisabled === "undefined") {
  throw new Error("toggleElemDisabled() is required and is not defined");
}

// throw an error if required globals not defined
if (typeof API_BASE_URL === "undefined") {
  throw new Error("API_BASE_URL is required and is not defined");
}

/* TODO: replace shorthands with $(document).ready(...) its more verbose */
$(function() {
  var accordionActive = false;

  $(window).on('resize', function() {
    var windowWidth = $(window).width();
    var $topMenu = $('#top-menu');
    var $sideMenu = $('#side-menu');
    var top_bar = $('.top-bar');
    var msg_bar = $('.message-bar');

    if (windowWidth < 768) {
      top_bar.show();
      msg_bar.hide();

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
      top_bar.hide();
      msg_bar.show();

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
    var $this = $(this);
    var $next = $this.next();
    var anchor = $this.find('a')

    $next.slideToggle();
    $this.parent().toggleClass('open');

    if (!e.data.multiple) {
      $el.find('.submenu').not($next).slideUp().parent().removeClass('open');
    }
  };

  var accordion = new Accordion($('ul.accordion'), false);
});

$(function() {
  /* styling links */
  $('a').each(function() {
    if ($(this).prop('href') === window.location.href) {
      $(this).removeClass('navlink');
      $(this).addClass('currentlink');
    }
  });
  /* prevent empty links from jumping to top of page */
  $('a[href$=\\#]').on('click', function(event) {
    event.preventDefault();
  });
});

/* TODO: do we have a use for this anymore? */
/* Update an attribute of an endpoint
/* row - Javascript DOM that contains the row of the PBX
 * attr - is the attribute that we want to update
 */
// function updateEndpoint(row, attr, attrvalue) {
//   checkbox = row.cells[0].getElementsByClassName('checkthis');
//   pbxid = checkbox[0].value;
//   requestPayload = '{"maintmode":' + attrvalue + '}';
//
//   $.ajax({
//     type: "POST",
//     url: "/api/v1/endpoint/" + pbxid,
//     dataType: "json",
//     contentType: "application/json; charset=utf-8",
//     success: function(response, text_status, xhr) {
//       // uncheck the Checkbox
//       if (attr === 'maintmode') {
//         $('#checkbox_' + pbxid)[0].checked = false;
//         if (attrvalue == 1) {
//           $('#maintmode_' + pbxid).html("<span class='glyphicon glyphicon-wrench'>");
//         }
//         else {
//           $('#maintmode_' + pbxid).html("");
//         }
//       }
//     },
//     data: requestPayload
//   });
// }

/* TODO: update to work with endpoint groups */
// function enableMaintenanceMode() {
//   var table = document.getElementById("pbxs");
//
//   r = 1;
//   while (row = table.rows[r++]) {
//     checkbox = row.cells[0].getElementsByClassName('checkthis');
//     if (checkbox[0].checked) {
//       updateEndpoint(row, 'maintmode', 1);
//     }
//   }
// }

/* TODO: update to work with endpoint groups */
// function disableMaintenanceMode() {
//   var table = document.getElementById("pbxs");
//
//   r = 1;
//   while (row = table.rows[r++]) {
//     checkbox = row.cells[0].getElementsByClassName('checkthis');
//     if (checkbox[0].checked) {
//       updateEndpoint(row, 'maintmode', 0);
//     }
//   }
// }

$(document).ready(function() {
  /* query param actions */
  if (getQueryString('action') === 'add') {
    $('#add').modal('show');
  }

  /* kam reload button listener */
  $('#reloadkam').click(function() {
    $.ajax({
      type: "GET",
      url: API_BASE_URL + "kamailio/reload",
      dataType: "json",
      global: false,
      success: function(response, text_status, xhr) {
        reloadKamRequired(false);
        showNotification("Kamailio was reloaded");
      },
      error: function(xhr, text_status, error_msg) {
        error_msg = JSON.parse(xhr.responseText)["msg"];
        showNotification("Kamailio was NOT reloaded: " + error_msg, true);
      }
    });
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

  /* remove non-printable ascii chars on paste */
  $('form input[type!="hidden"]').on("paste", function() {
    $(this).val(this.value.replace(/[^\x20-\x7E]+/g, ''))
  });

  /* make sure autofocus is honored on loaded modals */
  $('.modal').on('shown.bs.modal', function() {
    $(this).find('[autofocus]').focus();
  });
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
