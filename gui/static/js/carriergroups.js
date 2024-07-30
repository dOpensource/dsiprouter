;(function(window, document) {
  'use strict';

  // throw an error if required functions not defined
  if (typeof validateFields === "undefined") {
    throw new Error("validateFields() is required and is not defined");
  }
  if (typeof showNotification === "undefined") {
    throw new Error("showNotification() is required and is not defined");
  }
  if (typeof toggleElemDisabled === "undefined") {
    throw new Error("toggleElemDisabled() is required and is not defined");
  }

  // throw an error if required globals not defined
  if (typeof API_BASE_URL === "undefined") {
    throw new Error("API_BASE_URL is required and is not defined");
  }
  // throw an error if required globals not defined
  if (typeof GUI_BASE_URL === "undefined") {
    throw new Error("GUI_BASE_URL is required and is not defined");
  }

  // globals
  var gwgroupid;
  var gwgroup_table = $('').DataTable();
  var plugin_name_sel = $('#plugin_name');
  var plugin_name_regex = new RegExp('^([a-zA-Z0-9.-])+$');

  // when using twilio plugin we need to do some extra validation for
  function validatePluginData(fields) {
    if (plugin_name_sel.val() === "Twilio") {
      if (!plugin_name_regex.test(fields.get('name').val())) {
        return {
          result: false,
          err_node: fields.get('name'),
          err_msg: "Endpoint Group Name must be a valid hostname for the Twilio plugin"
        };
      }
      if (fields.get('plugin_account_sid').val() === '') {
        return {
          result: false,
          err_node: fields.get('plugin_account_sid'),
          err_msg: "Account SID is required for the Twilio plugin"
        };
      }
      if (fields.get('plugin_account_token').val() === '') {
        return {
          result: false,
          err_node: fields.get('plugin_account_token'),
          err_msg: "Account Token is required for the Twilio plugin"
        };
      }
    }

    return {
      result: true
    };
  }

  // Add EndpointGroup
  function addCarrierGroup(action) {
    var selector, modal_body, url;

    // The default action is a POST (creating a new EndpointGroup)
    if (typeof action === "undefined") {
      action = "POST";
    }

    // set the query parameters
    if (action === "POST") {
      action = "POST";
      selector = "#add-group";
      modal_body = $(selector + ' .modal-body');
      url = API_BASE_URL + "carriergroups";
    }
    else if (action === "PUT") {
      selector = "#edit-group";
      modal_body = $(selector + ' .modal-body');
      gwgroupid = modal_body.find(".gwgroup").val();
      url = API_BASE_URL + "carriergroups/" + gwgroupid;
    }
    else {
      throw new Error("addGatewayGroup(): action must be either POST or PUT");
    }

    var requestPayload = {};

    requestPayload.name = modal_body.find('.name').val();
    if (action === "PUT") {
      requestPayload.name = modal_body.find('.new_name').val();
    }

    if (plugin_name_sel.val() === "Twilio") {
      requestPayload.plugin = {
        name: plugin_name_sel.val(),
        account_sid: modal_body.find(".plugin_account_sid").val(),
        account_token: modal_body.find(".plugin_account_token").val(),
      };
    }

    var auth = {};
    if (action === "POST") {
      auth.type = modal_body.find(".authtype").val();
      if (auth.type == "userpwd") {
        auth.pass = modal_body.find(".auth_password").val();
      }
    }
    else if (action === "PUT") {
      auth.type = modal_body.find(".authtype").val();
      if (auth.type == "userpwd") {
        auth.pass = modal_body.find(".auth_password").val();
      }
    }
    auth.r_username = modal_body.find(".r_username").val();
    auth.auth_username = modal_body.find(".auth_username").val();
    auth.auth_password = auth.pass
    auth.auth_domain = modal_body.find(".auth_domain").val();
    auth.auth_proxy = modal_body.find(".auth_proxy").val();
    requestPayload.auth = auth;

    requestPayload.lb_enabled = modal_body.find('.lb_enabled').val();
    requestPayload.strip = modal_body.find(".strip").val();
    requestPayload.prefix = modal_body.find(".prefix").val();

    // Put into JSON Message and send over
    $.ajax({
      type: action,
      url: url,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: JSON.stringify(requestPayload),
      success: function(response, textStatus, jqXHR) {
        var btn;
        var gwgroupid_int = response.data[0].gwgroupid;

        // Update the Add Button and the table
        if (action === "POST") {
          btn = $('#add .modal-footer').find('#addButton');
          btn.removeClass("btn-primary");
        }
        else {
          btn = $('#edit .modal-footer').find('#updateButton');
          btn.removeClass("btn-warning");
        }

        btn.addClass("btn-success");
        btn.html("<span class='glyphicon glyphicon-check'></span> Saved!");
        btn.attr("disabled", true);

        if (action === "POST") {
          gwgroup_table.row.add({
            "name": requestPayload.name,
            "gwgroupid": gwgroupid_int
          }).draw();
          location.reload(true);
        }
        else {
          /*
          gwgroup_table.row(function(idx, data, node) {
            return data.gwgroupid === gwgroupid_int;
          }).data({
            "name": requestPayload.name,
            "gwgroupid": gwgroupid_int
          }).draw(); */
          location.reload(true);
        }
      }
    })
  }

  function updateCarrierGroup() {
    addCarrierGroup("PUT");
  }

  /* validate fields before submitting api request */
  $('#addButton').click(function(ev) {
    /* prevent form default submit */
    ev.preventDefault();

    if (validateFields('#add-group', validatePluginData)) {
      addCarrierGroup();
      // hide the modal after 1.5 sec
      setTimeout(function() {
        var add_modal = $('#add-group');
        if (add_modal.is(':visible')) {
          add_modal.modal('hide');
        }
      }, 1500);
    }
  });

  /* validate fields before submitting api request */
  $('#updateGroupButton').click(function(ev) {
    /* prevent form default submit */
    ev.preventDefault();

    if (validateFields('#edit-group')) {
      updateCarrierGroup();
      // hide the modal after 1.5 sec
      setTimeout(function() {
        var edit_modal = $('#edit-group');
        if (edit_modal.is(':visible')) {
          edit_modal.modal('hide');
        }
      }, 1500);
    }

    /* prevent page reload */
    return false;
  });

  function setCarrierGroupHandlers() {
    var carriergroups_tbody = $('#carrier-groups tbody');

    $('#carrier-nav').click(function(e) {
      var target_link = $(e.target);

      /* fix target if we hit an ancestor elem containing it */
      var target_type = $(e.target).get(0).nodeName.toLowerCase();
      if (target_type !== "a") {
        /* no routing necessary if these are clicked */
        if (['div', 'ul'].indexOf(target_type) > -1) {
          return false;
        }
        target_link = target_link.find('a');
      }

      var other_links = $(e.currentTarget).find('.nav-tabs a').not(target_link);
      var modal_body = $(e.currentTarget.parentNode);

      /* handle dynamic routes (links) */
      if (target_link.data("type") === "link") {
        /* add dynamic routes here for each link */
        if (target_link.attr("name") === "carriers-link") {
          var gwid = modal_body.find('.gwid').val();
          var gwgroup = modal_body.find('.gwgroup').val();

          if (gwgroup !== undefined) {
            target_link.attr('href', target_link.attr('href') + "/group/" + gwgroup);
          }
          else if (gwid !== undefined) {
            target_link.attr('href', target_link.attr('href') + "/" + gwid);
          }
        }

        /* add styling to the links */
        target_link.addClass('current-navlink');
        $.each(other_links, function(i, elem) {
          $(elem).removeClass('current-navlink');
        });

        /* make sure we follow the link after returning */
        return true;
      }

      /* handle dynamic modals (using toggles) */
      e.preventDefault();
      var modal_toggle_divs = modal_body.children('div[name*="toggle"]');
      for (var i = 0; i < modal_toggle_divs.length; i++) {
        if ($(modal_toggle_divs[i]).attr('name') === target_link.attr('name')) {
          $(modal_toggle_divs[i]).removeClass("hidden");
        }
        else {
          $(modal_toggle_divs[i]).addClass("hidden");
        }
      }

      // add styling to the toggles
      target_link.addClass('current-navlink');
      $.each(other_links, function(i, elem) {
        $(elem).removeClass('current-navlink');
      });

      // make sure we don't follow the link
      return false;
    });

    /* listener for plguin dropdown changes */
    plugin_name_sel.change(function() {
      var modal_body = $('#add-group .modal-body');

      // TODO: Use the carriergroup plugin architecture to get meta data about the plugin
      if ($(this).val() === '') {
        modal_body.find('#plugin_creds').addClass('hidden');
      }
      else {
        modal_body.find('#plugin_creds').removeClass('hidden');
      }
    });

    /* listener for load balancing toggle */
    $('.modal-body .toggle-loadbalancing').change(function() {
      var modal = $(this).closest('div.modal');
      var modal_body = modal.find('.modal-body');

      if ($(this).is(":checked") || $(this).prop("checked")) {
        modal_body.find('.lb_enabled').val(1);
      }
      else {
        modal_body.find('.lb_enabled').val(0);
      }
    });

    $('#open-CarrierGroupAdd').click(function() {
      /** Clear out the modal */
      var modal_body = $('#add-group .modal-body');
      modal_body.find(".name").val('');
      modal_body.find(".gwlist").val('');
      modal_body.find(".authtype").val('');
      modal_body.find(".r_username").val('');
      modal_body.find(".auth_username").val('');
      modal_body.find(".auth_password").val('');
      modal_body.find(".auth_domain").val('');
      modal_body.find(".auth_proxy").val('');

      /* reset plugin selections */
      plugin_name_sel.val('').change();

      /* reset toggle buttons */
      modal_body.find("input.toggle-loadbalancing").bootstrapToggle('off');

      // update gwgroup for all modals
      $('.modal-body').find(".gwgroup").each(function() {
        $(this).val('');
      });

      /* ip auth enabled by default, Set the radio button to true */
      modal_body.find('.authtype[data-toggle="ip_enabled"]').trigger('click');
    });

    carriergroups_tbody.on('click', '#open-Update', function() {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('carrier-groups');
      var gwgroup = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
      var name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
      var gwlist = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
      var authtype = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
      var r_username = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
      var auth_password = $(c).find('tr:eq(' + row_index + ') td:eq(6)').text();
      var auth_domain = $(c).find('tr:eq(' + row_index + ') td:eq(7)').text();
      var auth_username = $(c).find('tr:eq(' + row_index + ') td:eq(8)').text();
      var auth_proxy = $(c).find('tr:eq(' + row_index + ') td:eq(9)').text();
      var lb_enabled = $(c).find('tr:eq(' + row_index + ') td:eq(10)').text();

      // grab modals to change
      var modal_body = $('#edit-group .modal-body');
      var modal_bodies = $('.modal-body');

      /* update modal fields */
      modal_body.find(".name").val(name);
      modal_body.find(".new_name").val(name);
      modal_body.find(".gwlist").val(gwlist);
      modal_body.find(".authtype").val(authtype);
      modal_body.find(".r_username").val(r_username);
      modal_body.find(".auth_password").val(auth_password);
      modal_body.find(".auth_domain").val(auth_domain);
      modal_body.find(".auth_username").val(auth_username);
      modal_body.find(".auth_proxy").val(auth_proxy);

      /* update toggle buttons */
      if (lb_enabled === '1') {
        modal_body.find("input.toggle-loadbalancing").bootstrapToggle('on');
      }
      else {
        modal_body.find("input.toggle-loadbalancing").bootstrapToggle('off');
      }

      // update gwgroup for all modals
      modal_bodies.find(".gwgroup").each(function() {
        $(this).val(gwgroup);
      });

      if (authtype !== "") {
        /* userpwd auth enabled, Set the radio button to true */
        modal_body.find('.authtype[data-toggle="userpwd_enabled"]').trigger('click');
      }
      else {
        /* ip auth enabled, Set the radio button to true */
        modal_body.find('.authtype[data-toggle="ip_enabled"]').trigger('click');
      }

      /* only show carriers from current group */
      $('#carriers > tbody > tr').each(function() {
        if (gwlist.split(',').indexOf($(this).data('gwid').toString()) > -1) {
          $(this).removeClass('hidden');
        }
        else {
          $(this).addClass('hidden');
        }
      });

      /* start carrier-nav on first tab */
      $('#carrier-nav > .nav-tabs').find('a').first().trigger('click');
    });

    carriergroups_tbody.on('click', '#open-Delete', function() {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('carrier-groups');
      var gwgroup = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
      var name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
      var gwlist = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();

      /* update modal fields */
      var modal_body = $('#delete-group .modal-body');
      modal_body.find(".gwgroup").val(gwgroup);
      modal_body.find(".name").val(name);
      modal_body.find(".gwlist").val(gwlist);
    });
  }

  function setCarrierHandlers() {
    var carriers_tbody = $('#carriers tbody');

    $('#open-CarrierAdd').on('click', function() {
      /** Clear out the modal */
      var modal_body = $('#add .modal-body');
      modal_body.find(".gwid").val('');
      modal_body.find(".name").val('');
      modal_body.find(".ip_addr").val('');
      modal_body.find(".strip").val('');
      modal_body.find(".prefix").val('');
      modal_body.find(".rweight").val('');


      /* make sure ip_addr not disabled */
      modal_body.find('.ip_addr').prop('disabled', false);
    });


    carriers_tbody.on('click', '#open-Update', function() {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('carriers');
      var gwid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
      var name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
      var ip_addr = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
      var strip = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
      var prefix = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
      var rweight = $(c).find('tr:eq(' + row_index + ') td:eq(6)').text();

      /** Clear out the modal */
      var modal_body = $('#edit .modal-body');
      modal_body.find(".gwid").val('');
      modal_body.find(".name").val('');
      modal_body.find(".ip_addr").val('');
      modal_body.find(".strip").val('');
      modal_body.find(".prefix").val('');
      modal_body.find(".rweight").val('');

      /* update modal fields */
      modal_body.find(".gwid").val(gwid);
      modal_body.find(".name").val(name);
      modal_body.find(".ip_addr").val(ip_addr);
      modal_body.find(".strip").val(strip);
      modal_body.find(".prefix").val(prefix);
      modal_body.find(".rweight").val(rweight);
    });

    carriers_tbody.on('click', '#open-Delete', function() {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('carriers');
      var gwid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
      var name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
      var ip_addr = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
      var related_rules = JSON.parse($(c).find('tr:eq(' + row_index + ') td:eq(7)').text());

      var modal_body = $('#delete .modal-body');

      /* remove previous rules if they were created */
      modal_body.find('div.alert.alert-warning').remove();

      /* check if related dr_rules exist */
      if (Object.keys(related_rules).length > 0) {
        /* create an alert and append it to the DOM */
        var html_string = '<div class="alert alert-warning centered" role="alert">' +
          '<h4>Deleting this rule will cause the following Global Outbound Routes to be deleted</h4>' +
          '<hr>' + '<div class="table-responsive">' +
          '<table class="table table-centered" style="margin-bottom: 0;">' +
          '<thead><tr><th>RULE ID</th><th>NAME</th></tr></thead><tbody>';
        for (var key in related_rules) {
          html_string += '<tr><td>' + key + '</td><td>' + related_rules[key] + '</td></tr>';
        }
        html_string += '</tbody></table></div></div>';
        /* let jquery parse the string as html */
        var html_nodes = jQuery.parseHTML(html_string);
        modal_body.find("div.alert.alert-danger").after(html_nodes);
      }

      /* update modal fields */
      modal_body.find(".gwid").val(gwid);
      modal_body.find(".name").val(name);
      modal_body.find(".ip_addr").val(ip_addr);
      modal_body.find(".related_rules").val(JSON.stringify(related_rules));
    });
  }

  function setFormHandler(selector, successCallback) {
    $(selector).submit(function(e) {
      /* prevent form default submit */
      e.preventDefault();
      /* store reference to target for callback */
      var self = this;

      var request_url = $(this).attr("action");
      var request_method = $(this).attr("method");
      var form_data = $(this).serialize();

      $.ajax({
        url: request_url,
        type: request_method,
        data: form_data,
        success: function(data) {
          successCallback(data, self)
        },
        error: function(xhr, msg, err) {
          return true; // follow redirects for error page
        },
        complete: function() {
          $(e.target).closest('div.modal').modal('hide');
        }
      });

      /* make sure we don't reload page */
      return false;
    });
  }

  /* any handlers depending on DOM elements go here */
  $(document).ready(function() {
    /* update the carriers table */
    $.ajax({
      url: GUI_BASE_URL + "carriers",
      method: 'GET',
      headers: {
        'Content-Type': 'text/html,text/css,application/javascript,text/plain,*/*'
      },
      success: function(data) {
        $('#carriers-table').html(data);
      }
    });

    /* DataTable init */
    $('#carrier-groups').DataTable({
      "columnDefs": [
        {"orderable": true, "targets": [1, 2, 3]},
        {"orderable": false, "targets": [0, 4, 5, 6, 7, 8, 9, 10, 11]},
      ],
      "order": [[1, 'asc']]
    });

    /* update view when carriers updated */
    setFormHandler('.gwform', function(data, target) {
      $('#carriers-table').html(data);

      var modal = $(target).closest('div.modal');
      var gwid, gwgroup, td_gwlist, gwlist_arr, gwlist;
      if (modal.attr('id') === 'add') {
        gwid = $(data).find('tr.new_gw').data('gwid');
        gwgroup = modal.find('.gwgroup').val();
        td_gwlist = $('#carrier-groups').find('tr[data-gwgroup="' + gwgroup + '"] > td.gwlist');
        gwlist = td_gwlist.text();
        gwlist_arr = gwlist === '' ? [] : gwlist.split(',');
        gwlist_arr.push(gwid);
        gwlist = gwlist_arr.join(',');
        td_gwlist.text(gwlist);
      }
      else if (modal.attr('id') === 'delete') {
        gwid = modal.find('.gwid').val();
        gwgroup = modal.find('.gwgroup').val();
        td_gwlist = $('#carrier-groups').find('tr[data-gwgroup="' + gwgroup + '"] > td.gwlist');
        gwlist = td_gwlist.text();
        gwlist_arr = gwlist === '' ? [] : gwlist.split(',');
        gwlist_arr.splice(gwlist_arr.indexOf(gwid), 1);
        gwlist = gwlist_arr.join(',');
        td_gwlist.text(gwlist);
      }
    });

    setCarrierGroupHandlers();
  });

  /* any handlers that MAY rely on async calls put here */
  $(document).ajaxStop(function() {
    setCarrierHandlers();
  });

})(window, document);
