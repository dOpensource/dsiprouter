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
  if (typeof reloadKamRequired === "undefined") {
    throw new Error("reloadKamRequired() is required and is not defined");
  }

  // throw an error if required globals not defined
  if (typeof API_BASE_URL === "undefined") {
    throw new Error("API_BASE_URL is required and is not defined");
  }

  // global constants for this script
  const SIGNAL_OPTIONS = {
    "proxy": "Unaltered",
    "sip_udp": "SIP over UDP",
    "sip_tcp": "SIP over TCP",
    "sip_sctp": "SIP over SCTP",
    // "sip_ws": "SIP over WS",
    "sips_tls": "SIPS over TLS",
    "sips_sctp": "SIPS over SCTP",
    // "sips_wss": "SIPS over WSS"
  };
  const SIGNAL_OPTIONS_STR = JSON.stringify(SIGNAL_OPTIONS);
  // TODO: think of a more user friendly description for these options
  const MEDIA_OPTIONS = {
    "proxy": "Proxy Media",
    "direct": "Direct Media",
    "rtp_avp": "RTP/AVP",
    "rtp_savp": "RTP/SAVP",
    "rtp_avpf": "RTP/AVPF",
    "rtp_savpf": "RTP/SAVPF",
    "rtp_avp_any": "UDP/TLS/RTP/SAVP",
    "rtp_avpf_any": "UDP/TLS/RTP/SAVPF",
    "udptl": "T.38 over UDPTL",
    "osrtp_avp": "OSRTP over RTP/AVP",
    "osrtp_avpf": "OSRTP over RTP/AVPF"
  };
  const MEDIA_OPTIONS_STR = JSON.stringify(MEDIA_OPTIONS);
  const KEEPALIVE_OPTIONS = {
    0: "disabled",
    1: "enabled"
  };
  const KEEPALIVE_OPTIONS_STR = JSON.stringify(KEEPALIVE_OPTIONS);

  // global variables/constants for this script
  // TODO: find a way to pass these values around gwgroupid instead of using global
  var gwgroupid;
  var endpoint_table1;
  var endpoint_table2;
  var gwgroup_table;

  function generateEndpointObject(row) {
    var jq_row = $(row);
    return {
      gwid: parseInt(jq_row.find('input[name="gwid"]').val(), 10),
      host: jq_row.find('input[name="host"]').val(),
      port: parseInt(jq_row.find('input[name="port"]').val(), 10),
      signalling: jq_row.find('select[name="signalling"]').val(),
      media: jq_row.find('select[name="media"]').val(),
      description: jq_row.find('input[name="description"]').val(),
      rweight: parseInt(jq_row.find('input[name="rweight"]').val(), 10),
      keepalive: parseInt(jq_row.find('select[name="keepalive"]').val(), 10),
    };
  }

  /**
   * Generate the markup for an endpoint wrapped in a query object
   * @param endpoint
   * @returns jQuery
   */
  function generateEndpointMarkup(endpoint = null) {
    if (endpoint === null) {
      return $('<tr class="endpoint">' +
        '<td name="gwid"></td>' +
        '<td name="host"></td>' +
        '<td name="port"></td>' +
        '<td name="signalling"></td>' +
        '<td name="media"></td>' +
        '<td name="description"></td>' +
        '<td name="rweight">1</td>' +
        '<td name="keepalive"></td>' +
        '</tr>');
    }
    else {
      return $('<tr class="endpoint">' +
        '<td name="gwid">' + endpoint.gwid.toString() + '</td>' +
        '<td name="host">' + endpoint.host + '</td>' +
        '<td name="port">' + endpoint.port + '</td>' +
        '<td name="signalling">' + SIGNAL_OPTIONS[endpoint.signalling] + '</td>' +
        '<td name="media">' + MEDIA_OPTIONS[endpoint.media] + '</td>' +
        '<td name="description">' + endpoint.description + '</td>' +
        '<td name="rweight">' + endpoint.rweight.toString() + '</td>' +
        '<td name="keepalive">' + KEEPALIVE_OPTIONS[endpoint.keepalive] + '</td>' +
        '</tr>');
    }
  }

  function generateEndpointTable(selector) {
    var endpoint_table = $(selector);

    endpoint_table.Tabledit({
      columns: {
        identifier: [0, 'gwid'],
        editable: [
          [1, 'host'],
          [2, 'port'],
          [3, 'signalling', SIGNAL_OPTIONS_STR],
          [4, 'media', MEDIA_OPTIONS_STR],
          [5, 'description'],
          [6, 'rweight'],
          [7, 'keepalive', KEEPALIVE_OPTIONS_STR],
        ],
        saveButton: true,
      },
      ajaxDisabled: true,
      restoreButton: false
    });

    return endpoint_table;
  }

  // Add EndpointGroup
  function addEndpointGroup(action) {
    var selector, modal_body, url, tmp;

    // The default action is a POST (creating a new EndpointGroup)
    if (typeof action === "undefined") {
      action = "POST";
    }

    if (action === "POST") {
      action = "POST";
      selector = "#add";
      modal_body = $(selector + ' .modal-body');
      url = API_BASE_URL + "endpointgroups";
    }
    // Grab the Gateway Group ID if updating using a PUT
    else if (action === "PUT") {
      selector = "#edit";
      modal_body = $(selector + ' .modal-body');
      gwgroupid = modal_body.find(".gwgroupid").val();
      url = API_BASE_URL + "endpointgroups/" + gwgroupid;
    }
    else {
      throw new Error("addEndpointGroup(): action must be either POST or PUT");
    }

    var requestPayload = {};
    requestPayload.name = modal_body.find(".name").val();

    var call_settings = {};
    tmp = modal_body.find(".call_limit").val();
    call_settings.limit = tmp === '' ? null : tmp;
    tmp = modal_body.find(".call_timeout").val();
    call_settings.timeout = tmp === '' ? null : tmp;
    requestPayload.call_settings = call_settings;

    var auth = {};
    if (action === "POST") {
      if ($('input#ip.authtype').is(':checked')) {
        auth.type = "ip";
      }
      else {
        auth.type = "userpwd";
        auth.pass = modal_body.find("#auth_password").val();
      }
    }
    else if (action === "PUT") {
      if ($('input#ip2.authtype').is(':checked')) {
        auth.type = "ip";
      }
      else {
        auth.type = "userpwd";
        auth.pass = modal_body.find("#auth_password2").val();
      }
    }

    auth.user = modal_body.find(".auth_username").val();
    auth.domain = modal_body.find(".auth_domain").val();
    requestPayload.auth = auth;

    requestPayload.strip = modal_body.find(".strip").val();
    requestPayload.prefix = modal_body.find(".prefix").val();

    var notifications = {};
    notifications.overmaxcalllimit = modal_body.find(".email_over_max_calls").val();
    notifications.endpointfailure = modal_body.find(".email_endpoint_failure").val();
    requestPayload.notifications = notifications;

    var cdr = {};
    cdr.cdr_email = modal_body.find(".cdr_email").val();
    cdr.cdr_send_interval = modal_body.find(".cdr_send_minute").val() + ' ' +
      modal_body.find(".cdr_send_hour").val() + ' ' +
      modal_body.find(".cdr_send_day").val() + ' ' +
      modal_body.find(".cdr_send_month").val() + ' ' +
      modal_body.find(".cdr_send_weekday").val();
    requestPayload.cdr = cdr;

    var fusionpbx = {};
    fusionpbx.enabled = modal_body.find(".fusionpbx_db_enabled").val();
    fusionpbx.dbhost = modal_body.find(".fusionpbx_db_server").val();
    fusionpbx.dbuser = modal_body.find(".fusionpbx_db_username").val();
    fusionpbx.dbpass = modal_body.find(".fusionpbx_db_password").val();
    fusionpbx.clustersupport = modal_body.find(".fusionpbx_clustersupport").val();
    requestPayload.fusionpbx = fusionpbx;

    /* Process endpoints (empty endpoints are ignored) */
    requestPayload.endpoints = $("tr.endpoint").map(function(idx, row) {
      return generateEndpointObject(row);
    }).get();

    // set payload defaults for numbers
    // doing it here allows us to keep placeholder on the input
    if (requestPayload.strip.length === 0) {
      requestPayload.strip = 0;
    }

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

        // Update Reload buttons
        reloadKamRequired(true);

        if (action === "POST") {
          gwgroup_table.row.add({
            "name": requestPayload.name,
            "gwgroupid": gwgroupid_int
          }).draw();
        }
        else {
          gwgroup_table.row(function(idx, data, node) {
            return data.gwgroupid === gwgroupid_int;
          }).data({
            "name": requestPayload.name,
            "gwgroupid": gwgroupid_int
          }).draw();
        }
      }
    })
  }

  function updateEndpointGroup() {
    addEndpointGroup("PUT");
  }

  function clearEndpointGroupModal(modal_selector) {
    /** Clear out the modal */
    var modal_body = $(modal_selector).find('.modal-body');
    modal_body.find(".gwgroupid").val('');
    modal_body.find(".name").val('');
    modal_body.find(".ip_addr").val('');
    modal_body.find(".strip").val('');
    modal_body.find(".prefix").val('');
    modal_body.find(".fusionpbx_db_server").val('');
    modal_body.find(".fusionpbx_db_username").val('fusionpbx');
    modal_body.find(".fusionpbx_db_password").val('');
    modal_body.find(".authtype[value='ip']").trigger('click');
    modal_body.find(".auth_username").val('');
    modal_body.find(".auth_password").val('');
    modal_body.find(".auth_domain").val('');
    modal_body.find(".call_limit").val('');
    modal_body.find(".call_timeout").val('');
    modal_body.find(".email_over_max_calls").val('');
    modal_body.find(".email_endpoint_failure").val('');
    modal_body.find(".cdr_email").val('');
    modal_body.find(".cdr_send_minute").val('*');
    modal_body.find(".cdr_send_hour").val('*');
    modal_body.find(".cdr_send_day").val('1');
    modal_body.find(".cdr_send_month").val('*');
    modal_body.find(".cdr_send_weekday").val('*');
    modal_body.find('.FusionPBXDomainOptions').addClass("hidden");
    modal_body.find('.updateButton').attr("disabled", false);

    // Clear out update button in add footer
    var modal_footer = modal_body.find('.modal-footer');
    modal_footer.find("#addButton").attr("disabled", false);

    // Clear out update button in add footer
    modal_footer.find("#updateButton").attr("disabled", false);

    var btn;
    if (modal_selector == "#add") {
      btn = $('#add .modal-footer').find('#addButton');
      btn.html("<span class='glyphicon glyphicon-ok-sign'></span> Add");
      btn.removeClass("btn-success");
      btn.addClass("btn-primary");
    }
    else {
      btn = $('#edit .modal-footer').find('#updateButton');
      btn.html("<span class='glyphicon glyphicon-ok-sign'></span> Update");
      btn.removeClass("btn-success");
      btn.addClass("btn-warning");
    }
    btn.attr('disabled', false);

    // Remove Endpont Rows
    $("tr.endpoint").each(function(i, row) {
      $(this).remove();
    })

    /* start endpoint-nav on first tab */
    modal_body.find('#endpoint-nav .nav-tabs > li').removeClass("active");
    modal_body.find('#endpoint-nav > .nav-tabs a').first().trigger('click');

    // make sure userpwd options not shown
    modal_body.find('.userpwd').addClass('hidden');

    /* make sure ip_addr not disabled */
    toggleElemDisabled(modal_body.find('.ip_addr'), false);
  }

  function displayEndpointGroup(gwgroup_data) {
    var modal_body = $('#edit .modal-body');
    modal_body.find(".name").val(gwgroup_data.name);
    modal_body.find(".gwgroupid").val(gwgroup_data.gwgroupid);
    modal_body.find(".call_limit").val(gwgroup_data.call_settings.limit);
    modal_body.find(".call_timeout").val(gwgroup_data.call_settings.timeout);

    if (gwgroup_data.auth.type == "ip") {
      $('#ip2.authtype').prop('checked', true);
      $("#userpwd_enabled2").addClass('hidden');
      $("#userpwd_enabled").addClass('hidden');
    }
    else {
      $('#userpwd2.authtype').prop('checked', true);
      $("#userpwd_enabled2").removeClass('hidden');
      $("#userpwd_enabled").removeClass('hidden');
    }

    // parse the cdr_send_interval
    var send_interval = gwgroup_data.cdr.cdr_send_interval;

    modal_body.find(".auth_username").val(gwgroup_data.auth.user);
    modal_body.find("#auth_password2").val(gwgroup_data.auth.pass);
    modal_body.find("#auth_password").val(gwgroup_data.auth.pass);
    modal_body.find(".auth_domain").val(gwgroup_data.auth.domain);
    modal_body.find(".strip").val(gwgroup_data.strip);
    modal_body.find(".prefix").val(gwgroup_data.prefix);
    modal_body.find(".email_over_max_calls").val(gwgroup_data.notifications.overmaxcalllimit);
    modal_body.find(".email_endpoint_failure").val(gwgroup_data.notifications.endpointfailure);
    modal_body.find(".cdr_email").val(gwgroup_data.cdr.cdr_email);
    if (send_interval) {
      send_interval = send_interval.split(' ');
      modal_body.find(".cdr_send_minute").val(send_interval[0]);
      modal_body.find(".cdr_send_hour").val(send_interval[1]);
      modal_body.find(".cdr_send_day").val(send_interval[2]);
      modal_body.find(".cdr_send_month").val(send_interval[3]);
      modal_body.find(".cdr_send_weekday").val(send_interval[4]);
    }
    modal_body.find(".fusionpbx_db_enabled").val(gwgroup_data.fusionpbx.enabled);
    modal_body.find(".fusionpbx_db_server").val(gwgroup_data.fusionpbx.dbhost);
    modal_body.find(".fusionpbx_db_username").val(gwgroup_data.fusionpbx.dbuser);
    modal_body.find(".fusionpbx_db_password").val(gwgroup_data.fusionpbx.dbpass);
    modal_body.find(".fusionpbx_clustersupport").val(gwgroup_data.fusionpbx.clustersupport);

    /* reset the save button*/
    var updatebtn = $('#edit .modal-footer').find("#updateButton");
    updatebtn.removeClass("btn-success");
    updatebtn.addClass("btn-warning");
    updatebtn.html("<span class='glyphicon glyphicon-ok-sign'></span>Update");

    if (gwgroup_data.endpoints) {
      for (var i = 0; i < gwgroup_data.endpoints.length; i++) {
        endpoint_table1.append(generateEndpointMarkup(gwgroup_data.endpoints[i]));
      }
      endpoint_table1.data('Tabledit').reload();
    }

    if (gwgroup_data.fusionpbx.enabled) {
      modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('on');
    }
    else {
      modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('off');
    }

    if (gwgroup_data.auth.type == "userpwd") {
      /* userpwd auth enabled, Set the radio button to true */
      modal_body.find('.authtype[data-toggle="userpwd_enabled"]').trigger('click');
    }
    else {
      /* ip auth enabled, Set the radio button to true */
      modal_body.find('.authtype[data-toggle="ip_enabled"]').trigger('click');
    }
  }

  function deleteEndpointGroup() {
    var gwgroupid_int = parseInt(gwgroupid, 10);

    $.ajax({
      type: "DELETE",
      url: API_BASE_URL + "endpointgroups/" + gwgroupid,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function(response, textStatus, jqXHR) {
        $('#delete').modal('hide');
        $('#edit').modal('hide');

        // Update Reload buttons
        reloadKamRequired(true);

        gwgroup_table.row(function(idx, data, node) {
          return data.gwgroupid === gwgroupid_int;
        }).remove().draw();
      }
    });
  }

  $(document).ready(function() {
    // datatable init
    gwgroup_table = $('#endpointgroups').DataTable({
      "ajax": {
        "url": API_BASE_URL + "endpointgroups"
      },
      "columns": [
        {"data": "name"},
        {"data": "gwgroupid"}
        //{ "data": "gwlist", visible: false },
      ],
      "order": [[1, 'asc']]
    });

    // table editing by clicking on the row
    $('#endpointgroups tbody').on('click', 'tr', function() {
      //Turn off selected on any other rows
      $('#endpointgroups').find('tr').removeClass('selected');

      if ($(this).hasClass('selected')) {
        $(this).removeClass('selected');
      }
      else {
        //table.$('tr.selected').removeClass('selected');
        $(this).addClass('selected');
        gwgroupid = $(this).find('td').eq(1).text()
        //console.log(gwgroupid);
        $('#edit').modal('show');
      }
    });

    /* edit modal tabledit init */
    endpoint_table1 = generateEndpointTable('#endpoint-table');

    /* add modal tabledit init */
    endpoint_table2 = generateEndpointTable('#endpoint-table2');

    $('#edit').on('show.bs.modal', function() {
      clearEndpointGroupModal('#edit');

      // Show the auth tab by default when the modal shows
      var modal_body = $('#edit .modal-body');
      modal_body.find("[name='auth-toggle']").trigger('click');

      // Put into JSON Message and send over
      $.ajax({
        type: "GET",
        url: API_BASE_URL + "endpointgroups/" + gwgroupid,
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        success: function(response, textStatus, jqXHR) {
          displayEndpointGroup(response.data[0]);
        }
      })
    });

    $('#addEndpointRow').on('click', function() {
      endpoint_table2.append(generateEndpointMarkup());
      endpoint_table2.data('Tabledit').reload();
      endpoint_table2.find("tbody tr:last td:last .tabledit-edit-button").trigger("click");
    });

    $('#updateEndpointRow').on('click', function() {
      endpoint_table1.append(generateEndpointMarkup());
      endpoint_table1.data('Tabledit').reload();
      endpoint_table1.find("tbody tr:last td:last .tabledit-edit-button").trigger("click");
    });

    $('.modal-body .fusionpbx_clustersupport').change(function() {
      var modal = $(this).closest('div.modal');
      var modal_body = modal.find('.modal-body');

      if ($(this).is(":checked") || $(this).prop("checked")) {
        modal_body.find('.fusionpbx_clustersupport').val(1);
      }
      else {
        modal_body.find('.fusionpbx_clustersupport').val(0);
      }
    });

    /* listener for fusionPBX toggle */
    $('.modal-body .toggleFusionPBXDomain').change(function() {
      var self = $(this);
      var modal = self.closest('div.modal');
      var modal_body = modal.find('.modal-body');

      if (self.is(":checked") || self.prop("checked")) {
        modal_body.find('.FusionPBXDomainOptions').removeClass("hidden");
        modal_body.find('.fusionpbx_db_enabled').val(1);
        self.bootstrapToggle('on');
      }
      else {
        modal_body.find('.FusionPBXDomainOptions').addClass("hidden");
        modal_body.find('.fusionpbx_db_enabled').val(0);
        self.bootstrapToggle('off');
      }
    });

    /* listener for freePBX toggle */
    $('.modal-body .toggleFreePBXDomain').change(function() {
      var self = $(this);
      var modal = self.closest('div.modal');
      var modal_body = modal.find('.modal-body');

      if (self.is(":checked") || self.prop("checked")) {
        modal_body.find('.FreePBXDomainOptions').removeClass("hidden");
        modal_body.find('.freepbx_enabled').val(1);
        self.bootstrapToggle('on');
      }
      else {
        modal_body.find('.FreePBXDomainOptions').addClass("hidden");
        modal_body.find('.freepbx_enabled').val(0);
        self.bootstrapToggle('off');
      }
    });

    $(".toggle-password").on('click', function() {
      var input = $($(this).attr("toggle"));
      if (input.attr("type") == "password") {
        input.attr("type", "text");
        $(this).removeClass("glyphicon glyphicon-eye-close");
        $(this).addClass("glyphicon glyphicon-eye-open");
      }
      else {
        input.attr("type", "password");
        $(this).removeClass("glyphicon glyphicon-eye-open");
        $(this).addClass("glyphicon glyphicon-eye-close");
      }
    });

    $("#authoptions :input").change(function() {
      var userpwd_div = $('#userpwd_enabled');
      var authpwd_inp = $("#auth_password");
      var togglepwd_span = $(".toggle-password");

      if ($('#ip').is(':checked')) {
        userpwd_div.addClass('hidden');
      }
      else {
        $.ajax({
          type: "GET",
          url: API_BASE_URL + "sys/generatepassword",
          dataType: "json",
          contentType: "application/json; charset=utf-8",
          success: function(response, textStatus, jqXHR) {
            authpwd_inp.attr("type", "text");
            authpwd_inp.val(response.data[0])
            togglepwd_span.removeClass("glyphicon glyphicon-eye-close");
            togglepwd_span.addClass("glyphicon glyphicon-eye-open");
          }
        });

        userpwd_div.removeClass('hidden');
      }
    });

    $("#authoptions2 :input").change(function() {
      var userpwd_div = $('#userpwd_enabled2');

      if ($('#ip2').is(':checked')) {
        userpwd_div.addClass('hidden');
      }
      else {
        userpwd_div.removeClass('hidden');
      }
    });

    $('#open-EndpointGroupsAdd').click(function() {
      clearEndpointGroupModal('#add');
    });

    /* validate fields before submitting api request */
    $('#addButton').click(function(ev) {
      /* prevent form default submit */
      ev.preventDefault();

      if (validateFields('#add')) {
        addEndpointGroup();
        // hide the modal after 1.5 sec
        setTimeout(function() {
          var add_modal = $('#add');
          if (add_modal.is(':visible')) {
            add_modal.modal('hide');
          }
        }, 1500);
      }
    });

    /* validate fields before submitting api request */
    $('#updateButton').click(function(ev) {
      /* prevent form default submit */
      ev.preventDefault();

      if (validateFields('#edit')) {
        updateEndpointGroup();
        // hide the modal after 1.5 sec
        setTimeout(function() {
          var edit_modal = $('#edit');
          if (edit_modal.is(':visible')) {
            edit_modal.modal('hide');
          }
        }, 1500);
      }

      /* prevent page reload */
      return false;
    });

    /* handler for deleting endpoint group */
    $('#deleteButton').click(function() {
      deleteEndpointGroup();
    });

    /* validate fields before moving to next tab */
    $('#endpoint-nav > .nav-tabs').click({tab_panes: $('div.tab-content > div.tab-pane')}, function(ev) {
      var current_tab = ev.data.tab_panes.filter(':not(:hidden)');
      if (!validateFields(current_tab)) {
        return false;
      }
    });
  });

})(window, document);
