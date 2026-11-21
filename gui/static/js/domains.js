;(function(window, document) {
  'use strict';

  // pbx_type attr values, mirrors domainTypeFilter in gui/dsiprouter.py
  var PBX_TYPE_NAMES = {
    "0": "Static",
    "1": "Dynamic",
    "2": "Static using Dispatcher",
    "3": "MSTeams"
  };

  var domains_table;
  var domains_by_id = {};

  function escapeHtml(value) {
    return $('<div>').text(value === null || value === undefined ? '' : String(value)).html();
  }

  function apiErrorMessage(jqXHR) {
    if (jqXHR.responseJSON && jqXHR.responseJSON.msg) {
      return jqXHR.responseJSON.msg;
    }
    return "Request failed (" + jqXHR.status + ")";
  }

  /* enable / disable the inputs of ONE modal based on the selected domain type */
  function processDomainType(modal_selector) {
    var modal_body = $(modal_selector + ' .modal-body');
    var disabled = modal_body.find('.authtype').val() === "msteams-nosub";
    var is_msteams = modal_body.find('.authtype').val() === "msteams";

    modal_body.find(".domain_name").prop('disabled', disabled);
    modal_body.find(".notes").prop('disabled', disabled);
    modal_body.find(":submit").prop('disabled', disabled);
    // msteams domains route to the microsoft teams proxies, endpoint ids are ignored
    modal_body.find(".pbx_list").prop('disabled', disabled || is_msteams);
  }

  function resetDomainModal(modal_selector) {
    var modal_body = $(modal_selector + ' .modal-body');
    modal_body.find(".domain_id").val('');
    modal_body.find(".domain_name").val('');
    modal_body.find(".pbx_list").val('');
    modal_body.find(".notes").val('');
    modal_body.find('.authtype').val('');
    modal_body.find('.is-invalid').removeClass('is-invalid');
    processDomainType(modal_selector);
  }

  function parsePbxList(value) {
    return value.split(/[\s,]+/).map(function(item) {
      return item.trim();
    }).filter(function(item) {
      return item !== '';
    });
  }

  /* build the API payload from a modal form, returns null (and flags the field) when invalid */
  function domainFormToPayload(modal_selector, allow_multiple) {
    var modal_body = $(modal_selector + ' .modal-body');
    modal_body.find('.is-invalid').removeClass('is-invalid');

    var domain_field = modal_body.find('.domain_name');
    var domains = domain_field.val().split(',').map(function(item) {
      return item.trim();
    });
    if (domains.some(function(item) { return item === ''; })) {
      domain_field.addClass('is-invalid');
      showNotification("Domain can not be an empty string", true, 10000, false);
      return null;
    }
    if (!allow_multiple && domains.length > 1) {
      domain_field.addClass('is-invalid');
      showNotification("Only one domain can be edited at a time", true, 10000, false);
      return null;
    }

    var type_field = modal_body.find('.authtype');
    if (type_field.val() === '') {
      type_field.addClass('is-invalid');
      showNotification("Select a domain type", true, 10000, false);
      return null;
    }

    var payload = {
      domain: allow_multiple ? domains : domains[0],
      type: type_field.val(),
      notes: modal_body.find('.notes').val()
    };
    if (payload.type !== 'msteams') {
      payload.pbxs = parsePbxList(modal_body.find('.pbx_list').val());
    }
    return payload;
  }

  function sendDomainRequest(method, url, payload, modal_selector, success_msg) {
    var submit_btn = $(modal_selector + ' :submit');
    submit_btn.prop('disabled', true);

    $.ajax({
      type: method,
      url: url,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: payload === null ? undefined : JSON.stringify(payload),
      success: function(response) {
        $(modal_selector).modal('hide');
        reloadKamRequired(true);
        showNotification(success_msg);
        domains_table.ajax.reload(null, false);
      },
      error: function(jqXHR) {
        // keep the modal open so the user can fix the input
        showNotification(apiErrorMessage(jqXHR), true, 10000, false);
      },
      complete: function() {
        submit_btn.prop('disabled', false);
      }
    });
  }

  function renderCreatedBy(domain) {
    if (domain.managed_by === null) {
      return "Manually Created";
    }
    return '<a href="/endpointgroups?id=' + encodeURIComponent(domain.managed_by.gwgroupid) + '">' +
      escapeHtml(domain.managed_by.name || domain.managed_by.gwgroupid) + '</a>';
  }

  function renderActions(domain, can_edit) {
    if (!can_edit || !domain.editable) {
      return '';
    }
    var html = '<div class="btn-group" role="group">';
    html += '<button type="button" class="open-Update btn btn-primary btn-sm" title="Edit" data-id="' +
      domain.id + '"><i class="ti ti-pencil"></i></button>';
    if (domain.type === 'msteams') {
      html += '<a class="open-Test btn btn-warning btn-sm" title="Test MSTeams Connectivity" href="/domains/msteams/' +
        domain.id + '"><i class="ti ti-plane"></i></a>';
    }
    html += '<button type="button" class="open-Delete btn btn-danger btn-sm" title="Delete" data-id="' +
      domain.id + '"><i class="ti ti-trash"></i></button>';
    html += '</div>';
    return html;
  }

  $(document).ready(function() {
    var can_edit = $('#domains').data('can-edit') === true;

    domains_table = $('#domains').DataTable({
      "autoWidth": false,
      "ajax": {
        "url": API_BASE_URL + "domains",
        "dataSrc": function(response) {
          domains_by_id = {};
          (response.data || []).forEach(function(domain) {
            domains_by_id[domain.id] = domain;
          });
          return response.data || [];
        }
      },
      "rowId": function(domain) {
        return 'domain-' + domain.id;
      },
      "columns": [
        {"data": "id", "className": "domain_id"},
        {"data": "domain", "className": "domain_name", "render": $.fn.dataTable.render.text()},
        {
          "data": "pbx_type", "className": "domain_type", "render": function(data) {
            return PBX_TYPE_NAMES[data] || 'Unknown';
          }
        },
        {
          "data": null, "className": "pbx_name", "render": function(data, type, domain) {
            return renderCreatedBy(domain);
          }
        },
        {"data": "type", "className": "authtype", "render": $.fn.dataTable.render.text()},
        {
          "data": "pbxs", "className": "pbx_list", "render": function(data) {
            return escapeHtml((data || []).join(', '));
          }
        },
        {"data": "notes", "className": "notes", "render": $.fn.dataTable.render.text()},
        {
          "data": null, "orderable": false, "className": "actions", "render": function(data, type, domain) {
            return renderActions(domain, can_edit);
          }
        }
      ],
      "order": [[0, 'asc']]
    });

    $('#open-DomainAdd').on('click', function() {
      resetDomainModal('#add');
    });

    $('#domains tbody').on('click', '.open-Update', function() {
      var domain = domains_by_id[$(this).data('id')];
      if (domain === undefined) {
        return;
      }
      resetDomainModal('#edit');
      var modal_body = $('#edit .modal-body');
      modal_body.find('.domain_id').val(domain.id);
      modal_body.find('.domain_name').val(domain.domain);
      modal_body.find('.pbx_list').val((domain.pbxs || []).join(','));
      modal_body.find('.notes').val(domain.notes);
      // an unlicensed install shows msteams as msteams-nosub
      if (domain.type === 'msteams' && modal_body.find('.authtype option[value="msteams"]').length === 0) {
        modal_body.find('.authtype').val('msteams-nosub');
      }
      else {
        modal_body.find('.authtype').val(domain.type);
      }
      processDomainType('#edit');
      $('#edit').modal('show');
    });

    $('#domains tbody').on('click', '.open-Delete', function() {
      var domain = domains_by_id[$(this).data('id')];
      if (domain === undefined) {
        return;
      }
      var modal_body = $('#delete .modal-body');
      modal_body.find('.domain_id').val(domain.id);
      modal_body.find('.domain_name').text(domain.domain);
      modal_body.find(':submit').prop('disabled', false);
      $('#delete').modal('show');
    });

    $('#add .authtype').on('change', function() {
      processDomainType('#add');
    });

    $('#edit .authtype').on('change', function() {
      processDomainType('#edit');
    });

    $('#addDomainForm').on('submit', function(ev) {
      ev.preventDefault();
      var payload = domainFormToPayload('#add', true);
      if (payload !== null) {
        sendDomainRequest('POST', API_BASE_URL + "domains", payload, '#add',
          payload.domain.length > 1 ? "Domains added" : "Domain added");
      }
      return false;
    });

    $('#updateDomainForm').on('submit', function(ev) {
      ev.preventDefault();
      var domain_id = $('#edit .domain_id').val();
      var payload = domainFormToPayload('#edit', false);
      if (payload !== null) {
        sendDomainRequest('PUT', API_BASE_URL + "domains/" + domain_id, payload, '#edit', "Domain updated");
      }
      return false;
    });

    $('#deleteDomainForm').on('submit', function(ev) {
      ev.preventDefault();
      var domain_id = $('#delete .domain_id').val();
      sendDomainRequest('DELETE', API_BASE_URL + "domains/" + domain_id, null, '#delete', "Domain deleted");
      return false;
    });
  });
})(window, document);
