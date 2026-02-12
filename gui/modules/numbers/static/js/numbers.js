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

  // global variables/constants for this script
  var numbers_table;



 // Add or Update Number
  function addNumber(action) {
    var selector, modal_body, url, id;

    // The default action is a POST (creating a new Number)
    if (typeof action === "undefined") {
      action = "POST";
    }

    if (action === "POST") {
      action = "POST";
      selector = "#add";
      modal_body = $(selector + ' .modal-body');
      url = CUSTOM_MODULE_API_BASE_URL + "numbers/v1/number";
    }
     // Grab the Gateway Group ID if updating using a PUT
    else if (action === "PUT") {
      selector = "#edit";
      modal_body = $(selector + ' .modal-body');
      id = modal_body.find("input#id").val();
      console.log("Updating Number ID: " + id);
      url = CUSTOM_MODULE_API_BASE_URL  + "numbers/v1/number/" + id;
    }
    else {
      throw new Error("addNumber(): action must be either POST or PUT");
    }

    var requestPayload = {};
    requestPayload.did = modal_body.find("input#did").val();
    requestPayload.carrier = modal_body.find("input#carrier").val();
    requestPayload.pool = modal_body.find("input#pool").val();
    requestPayload.status = modal_body.find("select#status").val();
    requestPayload.assigned_length = modal_body.find("input#assigned_length").val();
    requestPayload.assigned_reference_id = modal_body.find("input#assigned_reference_id").val();
    


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
        btn.html("<span class='glyphicon glyphicon-check'></span> Saved!");
        btn.attr("disabled", true);

        // Update Reload buttons if the number was assigned
        if(requestPayload.status === "assigned") {
          reloadKamRequired(true);
        }

        if (action === "POST") {
          numbers_table.row.add({
            "id": response.data[0].id,
            "did": requestPayload.did,
            "status": requestPayload.status,
            "carrier": requestPayload.carrier,
            "pool": requestPayload.pool,
            "assigned_date": response.data[0].assigned_date,
            "assigned_length": requestPayload.assigned_length,
            "assigned_reference_id": requestPayload.assigned_reference_id
          }).draw();

          // Clear the form fields for next entry
           clearFormFields("#add");
        }
         
        else {
          numbers_table.row(function(idx, data, node) {
            return data.id === response.data[0].id;
          }).data({
            "id": response.data[0].id,
            "did": requestPayload.did,
            "status": requestPayload.status,
            "carrier": requestPayload.carrier,
            "pool": requestPayload.pool,
            "assigned_date": response.data[0].assigned_date,
            "assigned_length": requestPayload.assigned_length,
            "assigned_reference_id": requestPayload.assigned_reference_id
          }).draw();
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

  function deleteNumber(id) {
    var id_int = parseInt(id, 10);

    $.ajax({
      type: "DELETE",
      url: CUSTOM_MODULE_API_BASE_URL + "numbers/v1/number/" + id_int,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function(response, textStatus, jqXHR) {
        $('#delete').modal('hide');
        $('#edit').modal('hide');

        // Update Reload buttons
        reloadKamRequired(true);

        numbers_table.row(function(idx, data, node) {
          return data.id === id_int
        }).remove().draw();
      },
      error: function(jqXHR, textStatus, errorThrown) {
        showNotification("Delete Failed: " + jqXHR.responseText, true);
      }
    });
  }

  function bulkDelete() {
    var ids = [];
    $('.row-check:checked').each(function() {
      ids.push(parseInt($(this).val(), 10));
      console.log("Selected ID for deletion: " + $(this).val());
    });

    if (ids.length === 0) {
      showNotification("Bulk Delete Failed: No numbers selected", true);
      return;     
    }
    var requestPayload = {};
    requestPayload.id = ids;

    $.ajax({
      type: "DELETE",
      url: CUSTOM_MODULE_API_BASE_URL + "numbers/v1/number",
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: JSON.stringify(requestPayload),
      success: function(response, textStatus, jqXHR) {
        $('#bulk-delete').modal('hide');

        // Update Reload buttons
        //reloadKamRequired(true);

        // Remove deleted rows from table
        ids.forEach(function(id_int) {
          numbers_table.row(function(idx, data, node) {
            return parseInt(data.id, 10) === id_int;
          }).remove();
        });
        numbers_table.draw();

        showNotification("Bulk Delete Successful: Deleted " + response.data.length + " numbers.");
      },
      error: function(jqXHR, textStatus, errorThrown) {
        showNotification("Bulk Delete Failed: " + jqXHR.responseText, true);
      }
    });    
  } 

  function updateNumber() {
    addNumber("PUT");
  }

  function importNumbers() {
    var selector, modal_body, url, formData;

    selector = "#import";
    modal_body = $(selector + ' .modal-body');
    url = CUSTOM_MODULE_API_BASE_URL + "numbers/v1/number/bulk";

    formData = new FormData();
    var fileInput = modal_body.find("input#importFile")[0];
    if (fileInput.files.length > 0) {
      formData.append("file", fileInput.files[0]);
    } else {
      showNotification("Import Error", "No file selected for import.", "danger");
      return;
    }

    $.ajax({
      type: "POST",
      url: url,
      data: formData,
      processData: false,
      contentType: false,
      success: function(response, textStatus, jqXHR) {
        showNotification("Import Successful: "  + response.msg);
        numbers_table.ajax.reload();
        clearFormFields("#import");
      },
      error: function(jqXHR, textStatus, errorThrown) {
        showNotification("Import Error: Failed to import numbers " + jqXHR.responseText, true);
      }
    });

  }
   
  
  // on document ready

$(document).ready(function() {

    // datatable init
    numbers_table = $('#numbers-table').DataTable({
      "ajax": {
        "url": CUSTOM_MODULE_API_BASE_URL + "numbers/v1/number",
        "dataSrc": "data"
      },
      "columns": [
        {"data": null,
          render: function (data, type, row) {
        return `<input type="checkbox" class="row-check" value="${row.id}">`;
      }
        },
        {"data": "id"},
        {"data": "did"},
        {"data": "status"},
        {"data": "carrier"},
        {"data": "pool"},
        {"data": "assigned_date"},
        {"data": "assigned_length"},
        {"data": "assigned_reference_id"},
        {"data": null,
          render: function (data, type, row) {
          return `<button id="open-Update" class="open-Update btn btn-primary btn-xs" data-title="Edit" data-toggle="modal"
          data-target="#edit"><span class="glyphicon glyphicon-pencil"></span></button>`;
          }
        },
        {"data": null,
          render: function (data, type, row) {
          return `<button id="open-Delete" class="open-Delete btn btn-danger btn-xs" data-title="Delete" data-toggle="modal"
          data-target="#delete"><span class="glyphicon glyphicon-trash"></span></button>`;
          }
        }
      ],
      "order": [[1, 'asc']]
    });

    // handlers for dynamically created edit/delete buttons
    $('#numbers-table tbody').on('click', 'button.open-Update', function() {
      var data = numbers_table.row($(this).parents('tr')).data();
      $('#id').val(data.id);
      $('#did').val(data.did);
      $('#status').val(data.status);
      $('#carrier').val(data.carrier);
      $('#pool').val(data.pool);
      $('#assigned_date').val(data.assigned_date);
      $('#assigned_length').val(data.assigned_length);
      $('#assigned_reference_id').val(data.assigned_reference_id);
    });

    $('#numbers-table tbody').on('click', 'button.open-Delete', function() {
      var data = numbers_table.row($(this).parents('tr')).data();
      $('input#id').val(data.id);
    });

     /* validate fields before submitting api request */
    $('#addButton').click(function(ev) {
      /* prevent form default submit */
      ev.preventDefault();

      if (validateFields('#add')) {
        addNumber();
        // hide the modal after 1.5 sec
        setTimeout(function() {
          var add_modal = $('#add');
          if (add_modal.is(':visible')) {
            add_modal.modal('hide');
          }
        }, 1500);
      }
    });

     $('#updateButton').click(function(ev) {
      /* prevent form default submit */
      ev.preventDefault();

      if (validateFields('#edit')) {
        updateNumber();
        // hide the modal after 1.5 sec
        setTimeout(function() {
          var add_modal = $('#edit');
          if (add_modal.is(':visible')) {
            add_modal.modal('hide');
          }
        }, 1500);
      }

      /* prevent page reload */
      return false;
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
        deleteNumber(id);
      }
      else {
        bulkDelete();
      }


      numbers_table.row(function(idx, data, node) {
        return data.id === id;
      }).remove().draw()
      
    });

    $('#importButton').click(function(ev) {
      /* prevent form default submit */
      ev.preventDefault();

      importNumbers();

      // hide the modal after 1.5 sec
      setTimeout(function() {
        var import_modal = $('#import');
        if (import_modal.is(':visible')) {
          import_modal.modal('hide');
        }
      }, 1500);

    });

    
    

});  // document ready
  
})(window, document);