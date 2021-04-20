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
  var dnid_enrichment_table = $('').DataTable();

  // format url for API requests
  function getFormUrl(form) {
    var request_url = self.attr("action");

    if (form.data("method") === "PUT" || form.data("method") === "DELETE") {
      request_url = request_url + "/" + form.find(".rule_id").text();
    }

    return request_url;
  }

  // format data for API requests
  function getFormData(form) {
    if (form.data("method") === "POST") {
      return {
        "dnid": form.find(".dnid").text(),
        "country_code": form.find(".country_code").text(),
        "routing_number": form.find(".routing_number").text(),
        "rule_name": form.find(".rule_name").text()
      };
    }
    else if (form.data("method") === "PUT") {
      return {
        "rule_id": form.find(".rule_id").text(),
        "dnid": form.find(".dnid").text(),
        "country_code": form.find(".country_code").text(),
        "routing_number": form.find(".routing_number").text(),
        "rule_name": form.find(".rule_name").text()
      };
    }
    else if (form.data("method") === "DELETE") {
      return {
        "rule_id": form.find(".rule_id").text()
      };
    }
    else {
      return {};
    }
  }

  function clearModalData(selector) {
    /* validate selector */
    var select_node = null;
    if (typeof selector === 'string' || selector instanceof String) {
      select_node = $(selector);
    }
    else if (selector instanceof jQuery) {
      select_node = selector;
    }
    else if (typeof selector === "object" || selector instanceof Object) {
      select_node = $(selector);
    }
    else {
      throw new Error("clearModalData(): invalid selector argument");
    }

    var submit_btn;
    var modal_body = select_node.find('.modal-body');

    /* clear the modal data */
    modal_body.find(".rule_id").val('');
    modal_body.find(".dnid").val('');
    modal_body.find(".country_code").val('');
    modal_body.find(".routing_number").val('');
    modal_body.find(".rule_name").val('');

    /* reset the submit button */
    if (select_node.attr('id') === "add") {
      submit_btn = $('#submit-add-form');
      submit_btn.html("<span class='glyphicon glyphicon-ok-sign'></span> Add");
      submit_btn.removeClass("btn-success");
      submit_btn.addClass("btn-primary");
    }
    else if (select_node.attr('id') === "edit") {
      submit_btn = $('#submit-update-form');
      submit_btn.html("<span class='glyphicon glyphicon-ok-sign'></span> Update");
      submit_btn.removeClass("btn-success");
      submit_btn.addClass("btn-warning");
    }
    toggleElemDisabled(submit_btn, false);
  }

  function updateModalData(selector, data) {
    /* validate selector */
    var select_node = null;
    if (typeof selector === 'string' || selector instanceof String) {
      select_node = $(selector);
    }
    else if (selector instanceof jQuery) {
      select_node = selector;
    }
    else if (typeof selector === "object" || selector instanceof Object) {
      select_node = $(selector);
    }
    else {
      throw new Error("clearModalData(): invalid selector argument");
    }

    var submit_btn;
    var modal_body = select_node.find('.modal-body');

    /* clear the modal data */
    modal_body.find(".rule_id").val('');
    modal_body.find(".dnid").val('');
    modal_body.find(".country_code").val('');
    modal_body.find(".routing_number").val('');
    modal_body.find(".rule_name").val('');

    /* update the modal data */
    modal_body.find(".rule_id").val(data.rule_id);
    modal_body.find(".dnid").val(data.dnid);
    modal_body.find(".country_code").val(data.country_code);
    modal_body.find(".routing_number").val(data.routing_number);
    modal_body.find(".rule_name").val(data.rule_name);

    /* reset the submit button */
    if (select_node.attr('id') === "add") {
      submit_btn = $('#submit-add-form');
      submit_btn.html("<span class='glyphicon glyphicon-ok-sign'></span> Add");
      submit_btn.removeClass("btn-success");
      submit_btn.addClass("btn-primary");
    }
    else if (select_node.attr('id') === "edit") {
      submit_btn = $('#submit-update-form');
      submit_btn.html("<span class='glyphicon glyphicon-ok-sign'></span> Update");
      submit_btn.removeClass("btn-success");
      submit_btn.addClass("btn-warning");
    }
    toggleElemDisabled(submit_btn, false);
  }

  function setFormHandler(selector, successCallback=null) {
    /* validate selector */
    var select_node = null;
    if (typeof selector === 'string' || selector instanceof String) {
      select_node = $(selector);
    }
    else if (selector instanceof jQuery) {
      select_node = selector;
    }
    else if (typeof selector === "object" || selector instanceof Object) {
      select_node = $(selector);
    }
    else {
      throw new Error("setFormHandler(): invalid selector argument");
    }

    /* validate callback */
    if (successCallback === null) {
      successCallback = function(response, form_data) {};
    }
    else if (typeof successCallback !== "function") {
      throw new Error("setFormHandler(): sucessCallback must be a function");
    }

    /* form submit handler */
    select_node.submit(function(event) {
      /* prevent form default submit */
      event.preventDefault();
      /* store reference to form for callbacks */
      var self = $(this);

      /* return early if field validation fails */
      if (!validateFields(self)) {
        return false;
      }

      var request_url = getFormUrl(self);
      var request_method = self.data("method");
      var request_data = {"data": [getFormData(self)]};

      $.ajax({
        url: request_url,
        type: request_method,
        dataType: "json",
        contentType: "application/json; charset=utf-8",
        data: request_data,
        success: function(response, textStatus, jqXHR) {
          successCallback(response, request_data);
        }
      });

      /* make sure we don't reload page */
      return false;
    });
  }

  $(document).ready(function() {
    // only query re-used selectors at start
    var add_modal = $('#add');
    var delete_modal = $('#delete');
    var edit_modal = $('#edit');

    // datatable init
    dnid_enrichment_table = $('#dnid-enrichment-table').DataTable({
      "ajax": {
        "url": API_BASE_URL + "numberenrichment"
      },
      "columns": [
        {"data": "rule_id"},
        {"data": "dnid"},
        {"data": "rule_name"}
      ],
      "order": [[1, 'asc']]
    });

    // table editing by clicking on the row
    $('#dnid-enrichment-table tbody').on('click', 'tr', function() {
      var self = $(this);

      //Turn off selected on any other rows
      $('dnid-enrichment-table').find('tr').removeClass('selected');

      if (self.hasClass('selected')) {
        self.removeClass('selected');
      }
      else {
        self.addClass('selected');
        var rule_id = self.find('td').eq(0).text()

        $.ajax({
          type: "GET",
          url: API_BASE_URL + "numberenrichment/" + rule_id,
          dataType: "json",
          contentType: "application/json; charset=utf-8",
          success: function(response, textStatus, jqXHR) {
            updateModalData(response.data[0]);
            edit_modal.modal('show');
          }
        })
      }
    });

    $('#open-add-modal').click(function() {
      clearModalData(add_modal);
    });

    /* handler for add form submission */
    setFormHandler('#add form', function(response, form_data) {
      dnid_enrichment_table.row.add({
        "rule_id": response.data[0],
        "dnid": form_data["dnid"],
        "rule_name": form_data["rule_name"]
      }).draw();

      // hide the modal after 1.5 sec
      setTimeout(function() {
        if (add_modal.is(':visible')) {
          add_modal.modal('hide');
        }
      }, 1500);
    });

    /* handler for update form submission */
    setFormHandler('#edit form', function(response, form_data) {
      dnid_enrichment_table.row(function(idx, data, node) {
        return data.rule_id === parseInt(form_data["rule_id"], 10);
      }).data({
        "rule_id": response.data[0],
        "dnid": form_data["dnid"],
        "rule_name": form_data["rule_name"]
      }).draw();

      // hide the modal after 1.5 sec
      setTimeout(function() {
        if (edit_modal.is(':visible')) {
          edit_modal.modal('hide');
        }
      }, 1500);
    });

    /* handler for delete form submission */
    setFormHandler('#delete form', function(response, form_data) {
      dnid_enrichment_table.row(function (idx, data, node) {
          return data.rule_id === parseInt(form_data["rule_id"], 10);
      }).remove().draw();

      // hide the modals after 1.5 sec
      setTimeout(function() {
        if (delete_modal.is(':visible')) {
          delete_modal.modal('hide');
        }
        if (edit_modal.is(':visible')) {
          edit_modal.modal('hide');
        }
      }, 1500);
    });
  });

})(window, document);
