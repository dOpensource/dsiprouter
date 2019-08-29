// Updates the modal with the values from the endpointgroup API
function updateEndpointGroup(msg) {
  var modal_body = $('#edit .modal-body');
  modal_body.find(".name").val(msg.name);
  modal_body.find(".calllimit").val(msg.calllimit);

  modal_body.find(".authtype").val(msg.auth.type);
  modal_body.find(".auth_username").val(msg.auth.user);
  modal_body.find(".auth_password").val(msg.auth.pass);
  modal_body.find(".auth_domain").val(msg.auth.domain);

  modal_body.find(".strip").val(msg.strip);
  modal_body.find(".prefix").val(msg.prefix);

  modal_body.find(".email_over_max_calls").val(msg.notifications.overmaxcalllimit);
  modal_body.find(".email_endpoint_failure").val(msg.notifications.endpointfailure);

  modal_body.find(".fusionpbx_db_enabled").val(msg.fusionpbx.enabled);
  modal_body.find(".fusionpbx_db_server").val(msg.fusionpbx.dbhost);
  modal_body.find(".fusionpbx_db_username").val(msg.fusionpbx.dbuser);
  modal_body.find(".fusionpbx_db_password").val(msg.fusionpbx.dbpass);

  if (msg.endpoints) {

    var table = $('#endpoint-table');
    var body = $('#endpoint-tablebody');

    for (endpoint in msg.endpoints) {
      row = '<tr class="endpoint"><td name="pbxid"></td>';
      row += '<td name="hostname">' + msg.endpoints[endpoint].hostname + '</td>';
      row += '<td name="description">' + msg.endpoints[endpoint].description + '</td></tr>';
      table.append($(row));
    }

    table.data('Tabledit').reload();
  }

  if (msg.fusionpbx.enabled) {
    modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('on');
  } else {
    modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('off');
  }

  if (msg.auth.type === "userpwd") {
    /* userpwd auth enabled, Set the radio button to true */
    modal_body.find('.authtype[data-toggle="userpwd_enabled"]').trigger('click');
  } else {
    /* ip auth enabled, Set the radio button to true */
    modal_body.find('.authtype[data-toggle="ip_enabled"]').trigger('click');
  }
}

function deleteEndpointGroup() {
  $.ajax({
		type: "DELETE",
		url: "/api/v1/endpointgroups/" + gwgroupid,
		dataType: "json",
		contentType: "application/json; charset=utf-8",
		success: function(msg) {
        reloadkamrequired();
		}
  });


  $('#delete').modal('hide');
  $('#edit').modal('hide');
  $('#endpointgroups').DataTable().ajax.reload();
}

$(document).ready(function() {
  $('#endpointgroups').DataTable({
    "ajax": {
      "url": "/api/v1/endpointgroups",
      "dataSrc": "endpointgroups"
    },
    "columns": [
      {"data": "name"},
      {"data": "gwgroupid"}
      //{ "data": "gwlist", visible: false },

    ],

    "order": [[1, 'asc']]
  });

  $('#endpointgroups tbody').on('click', 'tr', function() {
    //Turn off selected on any other rows
    $('#endpointgroups').find('tr').removeClass('selected');

    if ($(this).hasClass('selected')) {
      $(this).removeClass('selected');
    } else {
      //table.$('tr.selected').removeClass('selected');
      $(this).addClass('selected');
      gwgroupid = $(this).find('td').eq(1).text()
      //console.log(gwgroupid);
      $('#edit').modal('show');
    }
  });

  $('#endpoint-table').Tabledit({
    //url: 'example.php',
    columns: {
      identifier: [0, 'id'],
      editable: [[1, 'col1'], [2, 'col2']],
      saveButton: true,
    },
    onAlways: function() {
      console.log("In Always");
      $('.tabledit-deleted-row').each(function(index, element) {
        $(this).remove();

      });
    }
  });

  $('#endpoint-table2').Tabledit({
    //url: 'example.php',
    columns: {
      identifier: [0, 'id'],
      editable: [[1, 'col1'], [2, 'col2']],
      saveButton: true,
    },
    onAlways: function() {
      console.log("In Always");
      $('.tabledit-deleted-row').each(function(index, element) {
        $(this).remove();

      });
    }
  });

  $('#edit').on('show.bs.modal', function() {
    //console.log("The current endpointgroup is " + gwgroupid);
    // Show the auth tab by default when the modal shows
    var modal_body = $('#edit .modal-body');
    modal_body.find("[name='auth-toggle']").trigger('click');

    // Put into JSON Message and send over
    $.ajax({
      type: "GET",
      url: "/api/v1/endpointgroups/" + gwgroupid,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function(msg) {
        updateEndpointGroup(msg)
      }
    })
  });

  $('#addEndpointRow').click(function() {
    var table = $('#endpoint-table2');
    var body = $('#endpoint-tablebody2');
    //var nextId = body.find('tr').length + 1;
    table.append($('<tr class="endpoint"><td name="pbxid"></td><td name="hostname"></td><td name="description"></td></tr>'));
    table.data('Tabledit').reload();
    $("#endpoint-table2" + " tbody tr:last td:last .tabledit-edit-button").trigger("click");
  });

  $('#updateEndpointRow').click(function() {
    var table = $('#endpoint-table');
    var body = $('#endpoint-tablebody');
    //var nextId = body.find('tr').length + 1;
    table.append($('<tr class="endpoint"><td name="pbxid"></td><td name="hostname"></td><td name="description"></td></tr>'));
    table.data('Tabledit').reload();
    $("#endpoint-table" + " tbody tr:last td:last .tabledit-edit-button").trigger("click");
  });

});