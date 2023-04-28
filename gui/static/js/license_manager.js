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

  // global variables/constants for this script
  var license_table = $('').DataTable();

  function activateLicense() {
    var selector = "#add";
    var modal_body = $(selector + ' .modal-body');
    var payload = {
      "license_key": modal_body.find(".key").val(),
      "key_encrypted": false,
    };

    $.ajax({
      type: "PUT",
      url: API_BASE_URL + "licensing/activate",
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: JSON.stringify(payload),
      success: function(response, textStatus, jqXHR) {
        if (response.error.length !== 0) {
          showNotification(response.msg, true);
          return;
        }

        hideModal('#add');
        showNotification(response.msg);

        license_table.row.add({
          "type": response.data[0].type,
          "license_key": response.data[0].license_key,
          "active": response.data[0].active,
          "valid": response.data[0].valid,
          "expires": response.data[0].expires,
        }).draw();
      },
    })
  }

  function deactivateLicense() {
    var modal_body = $('#delete .modal-body');

    var license_key = modal_body.find(".key").val().trim();

    var payload = {
      "license_key": license_key,
      "key_encrypted": false,
    };

    $.ajax({
      type: "PUT",
      url: API_BASE_URL + "licensing/deactivate",
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: JSON.stringify(payload),
      success: function(response, textStatus, jqXHR) {
        if (response.error.length !== 0) {
          showNotification(response.msg, true);
          return;
        }

        hideModal('#delete');
        showNotification(response.msg);

        license_table.row(function(idx, data, node) {
          return data.license_key === license_key;
        }).remove().draw();
      },
    });
  }

  // noinspection JSUnusedLocalSymbols
  function updateDeleteModal(self=null) {
    // attached via vanilla js event listener or called outside an event listener
    if (self === null) {
      self = $(this);
    }
    // attached via jQuery event listener
    else if (self instanceof jQuery.Event) {
      self = $(self.currentTarget);
    }
    // calling node passed ref to itself
    else {
      self = $(self);
    }

    var modal_body = $('#delete .modal-body');
    var license_key = self.closest('tr').find('.key').val().trim();

    modal_body.find(".key").val(license_key);
  }
  // export function to make it available in scope when called via dataTable widgets
  window.updateDeleteModal = updateDeleteModal;

  // noinspection JSUnusedLocalSymbols
  function togglePasswordHidden(self=null) {
    // attached via vanilla js event listener or called outside an event listener
    if (self === null) {
      self = $(this);
    }
    // attached via jQuery event listener
    else if (self instanceof jQuery.Event) {
      self = $(self.currentTarget);
    }
    // calling node passed ref to itself
    else {
      self = $(self);
    }

    var input = $(self.attr("data-toggle"));
    if (input.attr("type") === "password") {
      input.attr("type", "text");
      self.removeClass("glyphicon glyphicon-eye-close");
      self.addClass("glyphicon glyphicon-eye-open");
    }
    else {
      input.attr("type", "password");
      self.removeClass("glyphicon glyphicon-eye-open");
      self.addClass("glyphicon glyphicon-eye-close");
    }
  }
  // export function to make it available in scope when called via dataTable widgets
  window.togglePasswordHidden = togglePasswordHidden;

  function createDeleteButton() {
    return '' +
      '<div class="dt-resize-height">' +
      '  <button class="open-Delete btn btn-danger btn-xs" data-title="Deactivate" data-toggle="modal" data-target="#delete" onclick="updateDeleteModal(this)">' +
      '    <span class="glyphicon glyphicon-trash"></span>' +
      '  </button>' +
      '</div>';
  }

  function createLicenseKeyField(data, type, row, meta) {
    var unique_key_id = "key-" + meta.row;

    return '' +
      '<div class="wrapper-fieldicon-right dt-resize-height">' +
      '  <input id="' + unique_key_id + '" class="key" type="password" name="key" value="' + data + '" readonly>' +
      '  <span class="field-icon toggle-password glyphicon glyphicon-eye-close" data-toggle="#' + unique_key_id + '" onclick="togglePasswordHidden(this)"></span>' +
      '</div>';
  }

  function createReadonlyInputField(data, type, row, meta) {
    return '' +
      '<div class="dt-resize-height">' +
      '  <input type="text" value="' + data + '" readonly>' +
      '</div>';
  }

  function dtDrawCallback(settings) {
    var rows = $('#licensing > tbody > tr');
    var row_height = rows.eq(0).find('td:eq(0)').get(0).clientHeight;
    rows.find('td .dt-resize-height').css({'height': row_height});
  }

  function hideModal(selector) {
    var modal_elem = $(selector);
    // do nothing if not visible
    if (modal_elem.is(':visible')) {
      // hide the modal after 1.5 sec
      setTimeout(function() {
        modal_elem.modal('hide');
      }, 1500);
    }
  }

  $(document).ready(function() {
    // datatable init
    license_table = $('#licensing').DataTable({
      "ajax": {
        "url": API_BASE_URL + "licensing/list",
        "type": "GET",
        "error": function(xhr, error, code) {
          var response = JSON.parse(xhr.responseText);
          requestErrorHandler(xhr.status, response.msg, response.error);
        }
      },
      "columns": [
        {"data": "type", "render": createReadonlyInputField},
        {"data": "license_key", "render": createLicenseKeyField},
        {"data": "active", "render": createReadonlyInputField},
        {"data": "valid", "render": createReadonlyInputField},
        {"data": "expires", "render": createReadonlyInputField},
        {"data": null, "render": createDeleteButton, "searchable": false, "orderable": false},
      ],
      "order": [[0, 'asc']],
      "drawCallback": dtDrawCallback,
    });

    // make license key a password hidden field
    $(".toggle-password").on('click', togglePasswordHidden);

    // reset add modal before displaying
    $('#open-LicenseAdd').click(function() {
      var modal_body = $('#add .modal-body');
      var key = modal_body.find(".key");
      var toggle = modal_body.find(".toggle-password");

      // clear fields
      key.val('');

      // reset toggles
      if (key.attr("type") !== "password") {
        key.attr("type", "password");
        toggle.removeClass("glyphicon glyphicon-eye-open");
        toggle.addClass("glyphicon glyphicon-eye-close");
      }
    });

    // submit activation request to api
    $('#addButton').click(function(ev) {
      /* prevent form default submit */
      ev.preventDefault();

      if (validateFields('#add')) {
        activateLicense();
      }
    });

    // submit deactivation request to api
    $('#deleteButton').click(function(ev) {
      ev.preventDefault();

      deactivateLicense();
    });
  });

})(window, document);
