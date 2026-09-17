;(function(window, document) {
  'use strict';

  if (typeof showNotification === 'undefined') {
    throw new Error('showNotification() is required and is not defined');
  }
  if (typeof reloadKamRequired === 'undefined') {
    throw new Error('reloadKamRequired() is required and is not defined');
  }

  var endpoint = CUSTOM_MODULE_API_BASE_URL + 'security_settings/v1/pipelimit';
  var fieldIds = [
    'PIPELIMIT_HASH_SIZE',
    'PIPELIMIT_DB_URL',
    'PIPELIMIT_PLP_TABLE_NAME',
    'PIPELIMIT_PLP_PIPEID_COLUMN',
    'PIPELIMIT_PLP_LIMIT_COLUMN',
    'PIPELIMIT_PLP_ALGORITHM_COLUMN',
    'PIPELIMIT_TIMER_INTERVAL',
    'PIPELIMIT_TIMER_MODE',
    'PIPELIMIT_LOAD_FETCH',
    'PIPELIMIT_REPLY_CODE',
    'PIPELIMIT_REPLY_REASON',
    'PIPELIMIT_CLEAN_UNUSED'
  ];

  function parseIntegerField(id) {
    return parseInt($('#' + id).val(), 10);
  }

  function getFormPayload() {
    return {
      PIPELIMIT_HASH_SIZE: parseIntegerField('PIPELIMIT_HASH_SIZE'),
      PIPELIMIT_DB_URL: $('#PIPELIMIT_DB_URL').val(),
      PIPELIMIT_PLP_TABLE_NAME: $('#PIPELIMIT_PLP_TABLE_NAME').val(),
      PIPELIMIT_PLP_PIPEID_COLUMN: $('#PIPELIMIT_PLP_PIPEID_COLUMN').val(),
      PIPELIMIT_PLP_LIMIT_COLUMN: $('#PIPELIMIT_PLP_LIMIT_COLUMN').val(),
      PIPELIMIT_PLP_ALGORITHM_COLUMN: $('#PIPELIMIT_PLP_ALGORITHM_COLUMN').val(),
      PIPELIMIT_TIMER_INTERVAL: parseIntegerField('PIPELIMIT_TIMER_INTERVAL'),
      PIPELIMIT_TIMER_MODE: parseIntegerField('PIPELIMIT_TIMER_MODE'),
      PIPELIMIT_LOAD_FETCH: parseIntegerField('PIPELIMIT_LOAD_FETCH'),
      PIPELIMIT_REPLY_CODE: parseIntegerField('PIPELIMIT_REPLY_CODE'),
      PIPELIMIT_REPLY_REASON: $('#PIPELIMIT_REPLY_REASON').val(),
      PIPELIMIT_CLEAN_UNUSED: parseIntegerField('PIPELIMIT_CLEAN_UNUSED')
    };
  }

  function fillForm(data) {
    fieldIds.forEach(function(id) {
      if (Object.prototype.hasOwnProperty.call(data, id)) {
        $('#' + id).val(data[id]);
      }
    });
  }

  function loadPipelimitSettings() {
    $.ajax({
      type: 'GET',
      url: endpoint,
      dataType: 'json',
      success: function(response) {
        if (response && response.data && response.data.length > 0) {
          fillForm(response.data[0]);
        }
      },
      error: function(jqXHR) {
        var responseText = {};
        try {
          responseText = jQuery.parseJSON(jqXHR.responseText);
        } catch (err) {
          responseText.msg = 'Failed loading rate limiting settings';
        }
        showNotification('Load failed: ' + responseText.msg, true);
      }
    });
  }

  function savePipelimitSettings() {
    var saveBtn = $('#save-pipelimit');
    var payload = getFormPayload();

    saveBtn.prop('disabled', true);

    $.ajax({
      type: 'PUT',
      url: endpoint,
      dataType: 'json',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(payload),
      success: function() {
        showNotification('Rate limiting settings saved');
        reloadKamRequired(true);
      },
      error: function(jqXHR) {
        var responseText = {};
        try {
          responseText = jQuery.parseJSON(jqXHR.responseText);
        } catch (err) {
          responseText.msg = 'Unable to save rate limiting settings';
        }
        showNotification('Save failed: ' + responseText.msg, true);
      },
      complete: function() {
        saveBtn.prop('disabled', false);
      }
    });
  }

  $(document).ready(function() {
    loadPipelimitSettings();
    $('#save-pipelimit').on('click', savePipelimitSettings);
  });

})(window, document);
