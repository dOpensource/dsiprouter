;(function(window, document) {
  'use strict';

  if (typeof showNotification === 'undefined') {
    throw new Error('showNotification() is required and is not defined');
  }
  if (typeof reloadKamRequired === 'undefined') {
    throw new Error('reloadKamRequired() is required and is not defined');
  }

  var endpoint = CUSTOM_MODULE_API_BASE_URL + 'rate_limiting/v1/pike';
  var bannedHostsEndpoint = CUSTOM_MODULE_API_BASE_URL + 'rate_limiting/v1/banned_hosts';
  var fieldIds = [
    'PIKE_SAMPLING_TIME_UNIT',
    'PIKE_REQS_DENSITY_PER_UNIT',
    'PIKE_REMOVE_LATENCY',
    'PIKE_IPBAN_PERIOD'
  ];

  function parseIntegerField(id) {
    return parseInt($('#' + id).val(), 10);
  }

  function getFormPayload() {
    return {
      PIKE_SAMPLING_TIME_UNIT: parseIntegerField('PIKE_SAMPLING_TIME_UNIT'),
      PIKE_REQS_DENSITY_PER_UNIT: parseIntegerField('PIKE_REQS_DENSITY_PER_UNIT'),
      PIKE_REMOVE_LATENCY: parseIntegerField('PIKE_REMOVE_LATENCY'),
      PIKE_IPBAN_PERIOD: parseIntegerField('PIKE_IPBAN_PERIOD')
    };
  }

  function fillForm(data) {
    fieldIds.forEach(function(id) {
      if (Object.prototype.hasOwnProperty.call(data, id)) {
        $('#' + id).val(data[id]);
      }
    });
  }

  function loadPikeSettings() {
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

  function savePikeSettings() {
    var saveBtn = $('#save-pike');
    var payload = getFormPayload();

    saveBtn.prop('disabled', true);

    $.ajax({
      type: 'PUT',
      url: endpoint,
      dataType: 'json',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(payload),
      success: function(response) {
        var result = (response && response.data && response.data.length > 0) ? response.data[0] : {};

        // changes are applied live via the pike cfg framework, no reload needed
        reloadKamRequired(false);

        if (result.live_apply_failed) {
          showNotification(
            'Rate limiting settings saved, but could not be applied to the running Kamailio instance: ' +
            result.live_apply_msg + '. A manual Kamailio reload/restart may be required.',
            true
          );
        } else {
          showNotification('Rate limiting settings saved and applied immediately');
        }
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

  function loadBannedHosts() {
    var tbody = $('#banned-hosts-table tbody');
    var emptyEl = $('#banned-hosts-empty');
    var errorEl = $('#banned-hosts-error');

    errorEl.hide();
    emptyEl.hide();

    $.ajax({
      type: 'GET',
      url: bannedHostsEndpoint,
      dataType: 'json',
      success: function(response) {
        var hosts = (response && response.data) ? response.data : [];
        tbody.empty();

        if (hosts.length === 0) {
          emptyEl.show();
          return;
        }

        hosts.forEach(function(host) {
          var row = $('<tr></tr>');
          row.append($('<td></td>').text(host.ip));
          row.append($('<td></td>').text(host.expires));
          tbody.append(row);
        });
      },
      error: function() {
        tbody.empty();
        errorEl.show();
      }
    });
  }

  $(document).ready(function() {
    loadPikeSettings();
    loadBannedHosts();
    $('#save-pike').on('click', savePikeSettings);
    $('#banned-hosts-tab').on('shown.bs.tab', loadBannedHosts);
  });

})(window, document);
