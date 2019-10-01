//Add EndpointGroup
function addEndpointGroup(action) {

  /** Get data from the modal */


  // The default action is a POST (creating a new EndpointGroup)
  if (action == undefined) {
    action = "POST"
    selector = "#add"
    var modal_body = $(selector + ' .modal-body');
    url = "/api/v1/endpointgroups"
  }

  if (action == "PUT") {
      selector = "#edit"
      // Grab the Gateway Group ID if updating usinga PUT
      var modal_body = $(selector + ' .modal-body');
      gwgroupid = modal_body.find(".gwgroupid").val();
      url = "/api/v1/endpointgroups/" + gwgroupid
  }


  var requestPayload = new Object();

  requestPayload.name = modal_body.find(".name").val();
  requestPayload.calllimit = modal_body.find(".calllimit").val();

  auth = new Object();

  auth.type = modal_body.find(".authtype").val();
  auth.user = modal_body.find(".auth_username").val();
  auth.pass = modal_body.find(".auth_password").val();
  auth.domain = modal_body.find(".auth_domain").val();

  requestPayload.auth = auth;

  requestPayload.strip= modal_body.find(".strip").val();
  requestPayload.prefix = modal_body.find(".prefix").val();

  notifications = new Object()

  notifications.overmaxcalllimit = modal_body.find(".email_over_max_calls").val();
  notifications.endpointfailure = modal_body.find(".email_endpoint_failure").val();

  requestPayload.notifications = notifications

  fusionpbx = new Object()

  fusionpbx.enabled = modal_body.find(".fusionpbx_db_enabled").val();
  fusionpbx.dbhost = modal_body.find(".fusionpbx_db_server").val();
  fusionpbx.dbuser = modal_body.find(".fusionpbx_db_username").val();
  fusionpbx.dbpass = modal_body.find(".fusionpbx_db_password").val();

  requestPayload.fusionpbx = fusionpbx;


  /* Process endpoints */

  endpoints = new Array();

  $("tr.endpoint").each(function (i, row) {

    endpoint = new Object();
    endpoint.pbxid = $(this).find('td').eq(0).text();
    endpoint.hostname = $(this).find('td').eq(1).text();
    endpoint.description = $(this).find('td').eq(2).text();
    //endpoint.maintmode = $(this).find('td').eq(3).text();

    endpoints.push(endpoint);
  });

   requestPayload.endpoints=endpoints;



// Put into JSON Message and send over

  $.ajax({
		type: action,
		url: url,
		dataType: "json",
		contentType: "application/json; charset=utf-8",
		success: function(msg) {
			if (msg.status == 200) {
        // Update the Add Button to say saved
        if (action == "POST") {
          var btn=$('#add .modal-footer').find('#addButton');
          btn.removeClass("btn-primary");
        }
        else {
          var btn=$('#edit .modal-footer').find('#updateButton');
          btn.removeClass("btn-warning");
        }

        btn.addClass("btn-success");
        btn.html("<span class='glyphicon glyphicon-check'></span>Saved!");
				//Uncheck the Checkbox
					reloadkamrequired();
          $('#endpointgroups').DataTable().ajax.reload();
			}
			else {
        console.log("error during endpointgroup update");

			}

		},
		data: JSON.stringify(requestPayload)
  })
}


function updateEndpointGroup () {

  addEndpointGroup("PUT");
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

$('#open-EndpointGroupsAdd').click(function() {

  clearEndpointGroupModal();

})


function clearEndpointGroupModal() {

    /** Clear out the modal */

  var modal_body = $('#add .modal-body');
  modal_body.find(".gwgroupid").val('');
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
  modal_body.find(".calllimit").val('');
  modal_body.find(".email_over_max_calls").val('');
  modal_body.find(".email_endpoint_failure").val('');
  modal_body.find('.FusionPBXDomainOptions').addClass("hidden");

  // Remove Endpont Rows
  $("tr.endpoint").each(function (i, row) {
      $(this).remove();
  })

  // Make the Auth tab the default
  modal_body.find(".auth-tab").addClass("active");


  /* make sure ip_addr not disabled */
  toggleElemDisabled(modal_body.find('.ip_addr'), false);


}

function displayEndpointGroup(msg)
{
  clearEndpointGroupModal();

  var modal_body = $('#edit .modal-body');
  modal_body.find(".name").val(msg.name);
  modal_body.find(".gwgroupid").val(msg.gwgroupid);
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

	
  /* reset the save button*/
  updatebtn = $('#edit .modal-footer').find("#updateButton")
  updatebtn.removeClass("btn-success");
  updatebtn.addClass("btn-warning");
  updatebtn.html("<span class='glyphicon glyphicon-ok-sign'></span>Update");
 


  if (msg.endpoints) {

    var table = $('#endpoint-table');
    var body = $('#endpoint-tablebody');

    for (endpoint in msg.endpoints) {
      row = '<tr class="endpoint"><td name="pbxid">' + msg.endpoints[endpoint].pbxid + '</td>'
      row += '<td name="hostname">' + msg.endpoints[endpoint].hostname +'</td>'
      row += '<td name="description">' + msg.endpoints[endpoint].description + '</td></tr>'
      table.append($(row));
    }

    table.data('Tabledit').reload();

  }

  if (msg.fusionpbx.enabled) {
      modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('on');
  }
  else {
      modal_body.find(".toggleFusionPBXDomain").bootstrapToggle('off');
  }


  if (msg.auth.type == "userpwd") {
    /* userpwd auth enabled, Set the radio button to true */
    modal_body.find('.authtype[data-toggle="userpwd_enabled"]').trigger('click');
  }
  else {
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

  })


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

    clearEndpointGroupModal();
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
        displayEndpointGroup(msg)
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
