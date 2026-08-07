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

	var ENTITY="agents";
  var id;
  var agents_table;
  var url = CUSTOM_MODULE_API_BASE_URL + ENTITY + "/v1/agent";


  function clear(modal_selector) {
    /** Clear out the modal */
    var modal_body = $(modal_selector).find('.modal-body');

    var btn;
    if (modal_selector == "#add") {
      btn = $('#add .modal-footer').find('#addButton');
      btn.html("<i class='ti ti-circle-check'></i> Add");
      btn.removeClass("btn-success");
      btn.addClass("btn-primary");
      modal_body.find('#domain').val("");
    }
    else {
      btn = $('#edit .modal-footer').find('#updateButton');
      btn.html("<i class='ti ti-circle-check'></i> Update");
      btn.removeClass("btn-success");
      btn.addClass("btn-warning");
    }
    btn.attr('disabled', false);

  }

	function addEntity(action) {
		var selector, modal_body, url
		var requestPayload = {};
		
    url = CUSTOM_MODULE_API_BASE_URL + "agents/v1/agent";


		// The default action is a POST
		if (typeof action === "undefined") {
			action = "POST";
		}

		if (action === "POST") {
			action = "POST";
			selector = "#add";
			modal_body = $(selector + ' .modal-body');

		}
    else if (action === "PUT") {
			action = "PUT";
			selector = "#edit";
			modal_body = $(selector + ' .modal-body');
      // Set the ID in the payload and append to URL for PUT request
      requestPayload.id = modal_body.find("input#id").val()
      url = url + "/" + requestPayload.id;

		}

   
    requestPayload.type= modal_body.find("select#agent_type").val();
    requestPayload.project_id = modal_body.find("select#project_id").val();
    requestPayload.name = modal_body.find("input#agent_name").val();
    requestPayload.webhook_secret = modal_body.find("input#webhook_secret").val();
    requestPayload.tools = modal_body.find("select#toolchain").val();
    requestPayload.callback_email = modal_body.find("input#callback_email").val();
    requestPayload.instructions = modal_body.find("textarea#agent_instructions").val();
    
    


    // Put into JSON Message and send over
    $.ajax({
      type: action,
      url: url,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: JSON.stringify(requestPayload),
      success: function(response, textStatus, jqXHR) {
        var btn;

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
        btn.html("<i class='ti ti-check'></i> Saved!");
        btn.attr("disabled", true);

        // Update Reload buttons if the number was assigned
        if(requestPayload.status === "assigned") {
          reloadKamRequired(true);
        }

        if (action === "POST") {
          agents_table.row.add(response.data[0]).draw(false);

          // Clear the form fields for next entry
           clearFormFields("#add");
        }
         
        else {
          agents_table.row(function(idx, data, node) {
            return data.id === response.data[0].id;
          }).data(response.data[0]).draw(false);
        }

       

      },
      error: function(jqXHR, textStatus, errorThrown) {
        var responseText = jQuery.parseJSON(jqXHR.responseText);
        if (action === "POST") {
          var messageText = "Add Failed: " + responseText["msg"];
        }
        else {
          var messageText = "Update Failed: " + responseText["msg"];
        } 
        showNotification(messageText, true);
      }
    });

}


function updateWebhookUrlPreview(modalSelector) {
  var modal = $(modalSelector);
  var urlField = modal.find('.agent-webhook-url');
  var templateUrl = urlField.attr('data-webhook-template-url') || urlField.val() || '';
  var agentName = (modal.find('input.agent_name').val() || 'Agent Name').trim();

  urlField.val(templateUrl.replace(/Agent Name$/, agentName || 'Agent Name'));
}


function bindWebhookUrlPreview(modalSelector) {
  var modal = $(modalSelector);

  modal.find('input.agent_name').off('.webhookPreview').on('input.webhookPreview keyup.webhookPreview change.webhookPreview paste.webhookPreview', function() {
    updateWebhookUrlPreview(modal);
  });

  modal.off('shown.bs.modal.webhookPreview').on('shown.bs.modal.webhookPreview', function() {
    updateWebhookUrlPreview(modal);
  });
}


function deleteEntity(id) {
    $.ajax({
      type: "DELETE",
      url: url + "/" + id,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function(response, textStatus, jqXHR) {
        $('#delete').modal('hide');
        $('#edit').modal('hide');
        agents_table.ajax.reload(null, false);

        showNotification("Agent " + id + " was deleted");
      }
    });
  }

	$(document).ready(function() {

  
    var url = CUSTOM_MODULE_API_BASE_URL + "agents/v1/agent";

  bindWebhookUrlPreview('#add');
  bindWebhookUrlPreview('#edit');

		// datatable init
		agents_table = $('#' + ENTITY + "_table").DataTable({
			"ajax": {
				"url": url
			},
			"columns": [
				{"data": "id"},
				{"data": "name"},
				{"data": "type"},
        {"data": "project_id", "visible": false},
        {"data": "greeting_message", "visible": false},
        {"data": "instructions", "visible": false},
        {"data": "instructions_id", "visible": false},
        {"data": "guardrails", "visible": false},
        {"data": "training_website", "visible": false},
        {"data": "tools", "visible": false},
        {"data": "callback_email", "visible": false},
				{"data": null, render: function(data, type, row) {
          if (data.status === "0") {

            return "Stopped <button class='agentStatus btn btn.dataset.container=" + data.container_name + " btn-success btn-xs agent_stopped' id='agentStatus'><i class='ti ti-player-play'></i></button>";
          }
          else if (data.status === "1") {
            return "Started <button class='agentStatus btn btn.dataset.container=" + data.container_name + " btn-danger btn-xs agent_started' id='agentStatus'><i class='ti ti-player-stop'></i></button>";

          }
         }
        },
        {"data": "did_mapping"},
        {"data": "deployment_type", "visible": false},
        {"data": "deployment_profile_id", "visible": false},
        {"data": "container_name", "visible": false},
        {"data": "image_name", "visible": false},
        {"data": "created_at", "visible": false},
        {"data": "modified_at", "visible": false},
        {"data": "error", "visible": false},
        {"data": null,
          render: function (data, type, row) {
          return `<button id="open-Update" class="open-Update btn btn-primary btn-xs" data-title="Edit" data-bs-toggle="modal"
          data-bs-target="#edit"><i class="ti ti-pencil"></i></button>`;
          }
        },
        {"data": null,
          render: function (data, type, row) {
          return `<button id="open-Delete" class="open-Delete btn btn-danger btn-xs" data-title="Delete" data-bs-toggle="modal"
          data-bs-target="#delete"><i class="ti ti-trash"></i></button>`;
          }
        },

			],
			"order": [[1, 'asc']]
		});

    // handlers for dynamically created edit/delete buttons
    $('#' + ENTITY + "_table tbody").on('click', 'button.open-Update', function() {
      clear('#edit');
      var data = agents_table.row($(this).parents('tr')).data();
      var edit_modal_body = $('#edit .modal-body');
      var agent_type_select = edit_modal_body.find('select#agent_type');
      var project_select = edit_modal_body.find('select#project_id');

      function setSelectValue($select, value) {
        if (!value) {
          $select.val('');
          return;
        }

        if ($select.find("option[value='" + value + "']").length === 0) {
          $select.append($('<option></option>').val(value).text(value));
        }
        $select.val(value);
      }

      agent_type_select.val(data.type || '');

      // Load projects for the selected agent type before setting project_id.
      if ((data.type || '') === 'openai') {
        fetch('/api/agents/v1/projects/' + data.type)
          .then(response => response.json())
          .then(results => {
            project_select.html("<option value=''>Select Project ID</option>");
            results.data.forEach(project => {
              var option = document.createElement('option');
              option.value = project.id;
              option.textContent = project.name + ' - ' + project.id;
              project_select.append(option);
            });
            setSelectValue(project_select, data.project_id || '');
          })
          .catch(() => {
            setSelectValue(project_select, data.project_id || '');
          });
      }
      else {
        project_select.html("<option value=''>Select Project ID</option>");
        setSelectValue(project_select, data.project_id || '');
      }
      edit_modal_body.find('input#id').val(data.id || '');
      edit_modal_body.find('input#agent_name').val(data.name || '');
      edit_modal_body.find('input#webhook_secret').val(data.webhook_secret || '');
      updateWebhookUrlPreview('#edit');
      edit_modal_body.find('select#predefined_instructions').val(data.instructions_id || '');
      edit_modal_body.find('select#toolchain').val(data.tools || []);
      edit_modal_body.find('input#callback_email').val(data.callback_email || '');
      edit_modal_body.find('textarea#agent_instructions').val(data.instructions || '');
    });

    $('#' + ENTITY + "_table tbody").on('click', 'button.open-Delete', function() {
      var data = agents_table.row($(this).parents('tr')).data();
      var delete_modal_body = $('#delete .modal-body');

      delete_modal_body.find('input#id').val(data && data.id ? data.id : '');
    });


    // Status toggle handler
    $('#' + ENTITY + "_table tbody").on('click', 'button.agentStatus', function() {
      //e.stopPropagation();
      var data = agents_table.row($(this).parents('tr')).data();
      var agent_id = data.id;
      var action = $(this).hasClass("agent_stopped") ? "start" : "stop";
      $.ajax({
        type: "PUT",
        url: url + "/" + agent_id + "/" + action,
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        data: JSON.stringify({"agent_id": agent_id}),
        success: function(response, textStatus, jqXHR) {
          showNotification("Agent " + action + "ed successfully");
          agents_table.ajax.reload(null, false);
        },
        error: function(jqXHR, textStatus, errorThrown) {
          showNotification("Failed to " + action + " agent", true);
        }
      });
    });

		// table editing by clicking on the row
		$('#' + ENTITY + ' tbody').on('click', 'tr', function() {
			//Turn off selected on any other rows
			$('#' + ENTITY).find('tr').removeClass('selected');

			if ($(this).hasClass('selected')) {
				$(this).removeClass('selected');
			}
			else {
				//table.$('tr.selected').removeClass('selected');
				$(this).addClass('selected');
				id = $(this).find('td').eq(1).text()
				if (id != "") {
				      $('#edit').modal('show');
      }
			}
		});


  /*  fetch('/api/agents/v1/instructions')
      .then(response => response.json())
     .then(results => {
        var instructions_select = document.querySelector(".predefined_instructions");
        instructions_select.innerHTML = "<option value=''>Select Instruction Set</option>";
        results.data.forEach(instruction_set => {
          var option = document.createElement("option");
          option.value = instruction_set.id;
          option.textContent = instruction_set.name + " - " + instruction_set.id;
          instructions_select.appendChild(option);
        });
    })
*/

$('.predefined_instructions').change(function() {

  var instruction_id = $(this).val();
  if (instruction_id) {
    fetch('/api/agents/v1/instructions/' + instruction_id)
      .then(response => response.json())
      .then(result => {
        $(".agent_instructions").val(result.data[0].instructions);
      })
  }
  else {
    $(".agent_instructions").val("");
  }

})


$('#open-Add').click(function() {
      clear('#add');
  updateWebhookUrlPreview('#add');
});

$(document).on('click', '.copy-webhook-url', function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  ev.stopImmediatePropagation();

  var modal = $(this).closest('.modal');
  var webhookUrl = modal.find('.agent-webhook-url').val() || '';

  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(webhookUrl).then(function() {
      return;
    }).catch(function() {
      showNotification('Unable to copy webhook URL', true);
    });
    return;
  }

  var fallbackField = modal.find('.agent-webhook-url')[0];
  if (fallbackField) {
    fallbackField.select();
    fallbackField.setSelectionRange(0, fallbackField.value.length);
    try {
      document.execCommand('copy');
    }
    catch (error) {
      showNotification('Unable to copy webhook URL', true);
    }
  }

  return false;
});

/* validate fields before submitting api request */
$('#addButton').click(function() {
		if (validateFields('#add')) {
			addEntity('POST');
      // hide the modal after 1.5 sec
      setTimeout(function() {
        var add_modal = $('#add');
        if (add_modal.is(':visible')) {
          add_modal.modal('hide');
        }
      }, 1500);

		}
});

$('#updateButton').click(function() {
		if (validateFields('#edit')) {
			addEntity('PUT');
      // hide the modal after 1.5 sec
      setTimeout(function() {
        var edit_modal = $('#edit');
        if (edit_modal.is(':visible')) {
          edit_modal.modal('hide');
        }
      }, 1500);
		}
});

/* handler for deleting endpoint group */
$('#deleteButton').click(function(ev) {
      var selector, modal_body, id;
      /* prevent form default submit */
      ev.preventDefault();

      selector = "#delete";
      modal_body = $(selector + ' .modal-body');
      id = modal_body.find("input#id").val();
      if (id) {
        deleteEntity(id);
      }
      else {
        bulkDelete();
      }
    })



$(document).ajaxStart(function(){
  // Show image container
  $("#loader").show();
});
$(document).ajaxComplete(function(){
  // Hide image container
  $("#loader").hide();

});

$(".close").click(function () {

	document.getElementById("domain").value = "";
	$("#terminalDiv").addClass("hide");
	$("#terminalCommand").text("");
	$("#certtype_generate").prop('selected', true);
})

$(document).on('change', 'select.agent_type', function () {
  var modal_body = $(this).closest('.modal-body');
  var selected_type = $(this).val();
  var project_select = modal_body.find('select.project_id');

  if (selected_type === 'openai') {
    // Populate the project list only for the modal where the change happened.
    fetch('/api/agents/v1/projects/' + selected_type)
      .then(response => response.json())
      .then(results => {
        project_select.html("<option value=''>Select Project ID</option>");
        results.data.forEach(project => {
          var option = document.createElement('option');
          option.value = project.id;
          option.textContent = project.name + ' - ' + project.id;
          project_select.append(option);
        });
      });
  }
  else {
    project_select.html("<option value=''>Select Project ID</option>");
  }
});

$(document).on('change', 'select.project_id', function () {
  var modal_body = $(this).closest('.modal-body');
  var selected_text = $(this).find('option:selected').text();

  if ($(this).val()) {
    modal_body.find('input.agent_name').val(selected_text + ' agent');
  }
  else {
    modal_body.find('input.agent_name').val('');
  }
});


});

})(window, document);
