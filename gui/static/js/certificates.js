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

	var ENTITY="certificates";
  var id;
	var table;


  function clear(modal_selector) {
    /** Clear out the modal */
    var modal_body = $(modal_selector).find('.modal-body');

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

  }

	function addEntity(action) {
		var selector, modal_body, url;

		// The default action is a POST (creating a new EndpointGroup)
		if (typeof action === "undefined") {
			action = "POST";
		}

		if (action === "POST") {
			action = "POST";
			selector = "#add";
			modal_body = $(selector + ' .modal-body');
			url = API_BASE_URL + ENTITY;
		}

		var requestPayload = {};
		var type;

		requestPayload.domain = modal_body.find("#domain").val();
		if (modal_body.find(".certtype_generate").is(':checked')) {
				requestPayload.type = "generated"
        addGenerated(requestPayload)
		}
		else {
				requestPayload.type = "uploaded"
        addUploaded(requestPayload)
		}
}


function addUploaded (requestPayload) {

  var formData = new FormData(document.querySelector('#addCertificateForm'))

  $.ajax({
    url: API_BASE_URL + ENTITY + "/upload/" + requestPayload.domain,
    type: 'POST',
    data: formData,
    async: false,
    cache: false,
    contentType: false,
    processData: false,
    success: function(response, text_status, xhr) {
      showNotification("Certificates were uploaded");
    },
    error: function(xhr, text_status, error_msg) {
      showNotification("Certificates were NOT uploaded", true);
    }
  });

  return false;

}

function addGenerated(requestPayload) {
		// Put into JSON Message and send over
    $.ajax({
      type: action,
      url: url,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: JSON.stringify(requestPayload),
      success: function(response, textStatus, jqXHR) {
        var btn;
        var id_int = response.data[0].id;

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
        btn.html("<span class='glyphicon glyphicon-check'></span>Saved!");
        btn.attr("disabled", true);

        if (action === "POST") {
          table.row.add({
            "id": id_int,
            "domain": requestPayload.domain,
            "type": requestPayload.type,
            "assigned_domains": ''
          }).draw();
        }
        else {
          table.row(function(idx, data, node) {
            return data.id === id_int;
          }).data({
            "domain": requestPayload.domain,
            "id": id_int
          }).draw();
        }
      }
    });
	}

function deleteEntity() {
    var id_int = parseInt(id, 10);

    $.ajax({
      type: "DELETE",
      url: API_BASE_URL + ENTITY + "/" + id,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function(response, textStatus, jqXHR) {
        $('#delete').modal('hide');
        $('#edit').modal('hide');
        table.row(function (idx, data, node) {
            //return data.id === id_int;
            return data.domain === id;
        }).remove().draw();
      }
    });
  }

	$(document).ready(function() {
		// datatable init
		table = $('#' + ENTITY).DataTable({
			"ajax": {
				"url": API_BASE_URL + ENTITY
			},
			"columns": [
				{"data": "id"},
				{"data": "domain"},
				{"data": "type"},
				{"data": "assigned_domains"}
				//{ "data": "gwlist", visible: false },
			],
			"order": [[1, 'asc']]
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
				//console.log(gwgroupid);
				$('#edit').modal('show');
			}
		});


$('#open-Add').click(function() {
      clear('#add');
});

/* validate fields before submitting api request */
$('#addButton').click(function() {
		if (validateFields('#add')) {
			addEntity();
			// hide the modal after 1.5 sec
			setTimeout(function() {


			var add_modal = $('#add');
				if (add_modal.is(':visible')) {
					add_modal.modal('hide');
				}
			}, 1500);
		}
});

/* handler for deleting endpoint group */
$('#deleteButton').click(function() {
  deleteEntity();
});

$("#domain").keyup(function () {
	var value = document.getElementById("domain").value;
	console.log(value);
	if (value.includes("*")) {

		var command = "dsiprouter generatecert ";
		$("#terminalCommand").text(command + value);
		$("#terminalDiv").removeClass("hide");
	}
	else {

		$("#terminalDiv").addClass("hide");
	}

})

$("#certtype_generate").change(function () {

	$("#generate").removeClass("hide");
	$("#upload").addClass("hide");
})

$("#certtype_upload").change(function () {

	$("#generate").addClass("hide");
	$("#upload").removeClass("hide");
})


$(".close").click(function () {

	document.getElementById("domain").value = "";
	$("#terminalDiv").addClass("hide");
	$("#terminalCommand").text("");
	$("#certtype_generate").prop('selected', true);
})

})

})(window, document);
