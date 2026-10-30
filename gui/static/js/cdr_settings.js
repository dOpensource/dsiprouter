;(function(window, document) {
  'use strict';

  var SETTINGS_URL = API_BASE_URL + "settings/cdr";
  var S3_TEXT_FIELDS = ['CDR_S3_BUCKET', 'CDR_S3_PREFIX', 'CDR_S3_REGION', 'CDR_S3_ENDPOINT', 'CDR_S3_ACCESS_KEY'];
  var WEBHOOK_TEXT_FIELDS = ['CDR_WEBHOOK_URL', 'CDR_WEBHOOK_METHOD', 'CDR_WEBHOOK_AUTH', 'CDR_WEBHOOK_USERNAME'];
  var ENDPOINT_REGEX = /^https?:\/\/[A-Za-z0-9.\-]+(:[0-9]{1,5})?(\/\S*)?$/;
  var WEBHOOK_URL_REGEX = /^https?:\/\/(\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9.\-]+)(:[0-9]{1,5})?(\/\S*)?$/;

  var secret_saved = false;
  var webhook_password_saved = false;

  function escapeHtml(value) {
    return $('<div>').text(value === null || value === undefined ? '' : String(value)).html();
  }

  function apiErrorMessage(jqXHR) {
    if (jqXHR.responseJSON && jqXHR.responseJSON.msg) {
      return jqXHR.responseJSON.msg;
    }
    return "Request failed (" + jqXHR.status + ")";
  }

  function field(name) {
    return $('#cdrSettingsForm #' + name);
  }

  function toggleS3Fields() {
    var enabled = field('CDR_ARCHIVE_ENABLED').prop('checked');
    $('#cdr-s3-fields').toggle(enabled);
    $('#cdr-s3-fields :input').prop('disabled', !enabled);
    $('#cdr-test-s3').prop('disabled', !enabled);
  }

  function toggleWebhookFields() {
    var enabled = field('CDR_WEBHOOK_ENABLED').prop('checked');
    var basic = field('CDR_WEBHOOK_AUTH').val() === 'basic';
    $('#cdr-webhook-fields').toggle(enabled);
    $('#cdr-webhook-fields :input').prop('disabled', !enabled);
    $('#cdr-webhook-auth-fields').toggle(basic);
    $('#cdr-webhook-auth-fields :input').prop('disabled', !enabled || !basic);
    $('#cdr-test-webhook').prop('disabled', !enabled);
    // CDRs are always stored while nothing else receives them
    if (!enabled) {
      field('CDR_STORE_CDR').prop('checked', true);
    }
    field('CDR_STORE_CDR').prop('disabled', !enabled);
  }

  function toggleFields() {
    toggleS3Fields();
    toggleWebhookFields();
  }

  function summarizeResult(result) {
    var deleted = result.deleted || {};
    var parts = Object.keys(deleted).map(function(table) {
      return deleted[table] + " " + table;
    });
    var text = "deleted " + (parts.length > 0 ? parts.join(", ") : "nothing");
    var files = result.archived_files || [];
    if (files.length > 0) {
      text += ", archived " + files.length + " file" + (files.length === 1 ? "" : "s");
    }
    return text;
  }

  function showLastRun(last_run) {
    var el = $('#cdr-last-run');
    if (!last_run) {
      el.text("The retention job has not run yet.");
      return;
    }
    var result = last_run.result || {};
    var text = "Last run " + last_run.at + " (" + (result.trigger || "cron") + "): " + summarizeResult(result);
    if (result.error) {
      text += ". Archive failed: " + result.error;
    }
    el.text(text);
  }

  function showWebhookLastRun(last_run) {
    var el = $('#cdr-webhook-last-run');
    if (!last_run) {
      el.text("The webhook has not sent anything yet.");
      return;
    }
    var result = last_run.result || {};
    var text = "Last webhook run " + last_run.at + " (" + (result.trigger || "cron") + "): sent " + (result.sent || 0) + " CDR" +
      (result.sent === 1 ? "" : "s");
    if (result.deleted) {
      text += ", deleted " + result.deleted + " after delivery";
    }
    if (result.error) {
      text += ". Failed: " + result.error;
    }
    el.text(text);
  }

  function fillForm(data) {
    field('CDR_RETENTION_DAYS').val(data.CDR_RETENTION_DAYS);
    field('CDR_ARCHIVE_ENABLED').prop('checked', data.CDR_ARCHIVE_ENABLED === true);
    S3_TEXT_FIELDS.forEach(function(name) {
      field(name).val(data[name] || '');
    });
    secret_saved = data.CDR_S3_SECRET_KEY_SET === true;
    field('CDR_S3_SECRET_KEY').val('').attr('placeholder', secret_saved ? "Saved, leave empty to keep it" : "");
    field('CDR_WEBHOOK_ENABLED').prop('checked', data.CDR_WEBHOOK_ENABLED === true);
    field('CDR_STORE_CDR').prop('checked', data.CDR_STORE_CDR !== false);
    WEBHOOK_TEXT_FIELDS.forEach(function(name) {
      field(name).val(data[name] || '');
    });
    field('CDR_WEBHOOK_METHOD').val(data.CDR_WEBHOOK_METHOD || 'POST');
    webhook_password_saved = data.CDR_WEBHOOK_PASSWORD_SET === true;
    field('CDR_WEBHOOK_PASSWORD').val('').attr('placeholder', webhook_password_saved ? "Saved, leave empty to keep it" : "");
    $('#cdrSettingsForm :input').removeClass('is-invalid');
    toggleFields();
    showLastRun(data.CDR_LAST_RUN);
    showWebhookLastRun(data.CDR_WEBHOOK_LAST_RUN);
  }

  function loadSettings() {
    $.ajax({
      type: "GET",
      url: SETTINGS_URL,
      dataType: "json",
      success: function(response) {
        fillForm(response.data[0]);
      },
      error: function(jqXHR) {
        showNotification(escapeHtml(apiErrorMessage(jqXHR)), true, 10000, false);
      }
    });
  }

  /* the S3 values currently in the form, the secret only when one was typed */
  function s3Payload() {
    var payload = {};
    S3_TEXT_FIELDS.forEach(function(name) {
      payload[name] = field(name).val().trim();
    });
    var secret = field('CDR_S3_SECRET_KEY').val();
    if (secret !== '') {
      payload.CDR_S3_SECRET_KEY = secret;
    }
    return payload;
  }

  /* the webhook values currently in the form, the password only when one was typed */
  function webhookPayload() {
    var payload = {};
    WEBHOOK_TEXT_FIELDS.forEach(function(name) {
      payload[name] = field(name).val().trim();
    });
    var password = field('CDR_WEBHOOK_PASSWORD').val();
    if (password !== '') {
      payload.CDR_WEBHOOK_PASSWORD = password;
    }
    return payload;
  }

  function markInvalid(name, invalid) {
    field(name).toggleClass('is-invalid', invalid);
    return invalid;
  }

  function validateForm() {
    var invalid = false;
    var days = field('CDR_RETENTION_DAYS').val().trim();
    invalid = markInvalid('CDR_RETENTION_DAYS', !/^\d+$/.test(days) || parseInt(days, 10) > 36500) || invalid;

    if (field('CDR_ARCHIVE_ENABLED').prop('checked')) {
      invalid = markInvalid('CDR_S3_BUCKET', field('CDR_S3_BUCKET').val().trim() === '') || invalid;
      invalid = markInvalid('CDR_S3_ACCESS_KEY', field('CDR_S3_ACCESS_KEY').val().trim() === '') || invalid;
      invalid = markInvalid('CDR_S3_SECRET_KEY', !secret_saved && field('CDR_S3_SECRET_KEY').val() === '') || invalid;
      var endpoint = field('CDR_S3_ENDPOINT').val().trim();
      invalid = markInvalid('CDR_S3_ENDPOINT', endpoint !== '' && !ENDPOINT_REGEX.test(endpoint)) || invalid;
    }
    else {
      $('#cdr-s3-fields :input').removeClass('is-invalid');
    }

    if (field('CDR_WEBHOOK_ENABLED').prop('checked')) {
      invalid = markInvalid('CDR_WEBHOOK_URL', !WEBHOOK_URL_REGEX.test(field('CDR_WEBHOOK_URL').val().trim())) || invalid;
      if (field('CDR_WEBHOOK_AUTH').val() === 'basic') {
        var username = field('CDR_WEBHOOK_USERNAME').val().trim();
        invalid = markInvalid('CDR_WEBHOOK_USERNAME', username === '' || username.indexOf(':') !== -1) || invalid;
        invalid = markInvalid('CDR_WEBHOOK_PASSWORD', !webhook_password_saved && field('CDR_WEBHOOK_PASSWORD').val() === '') || invalid;
      }
      else {
        $('#cdr-webhook-auth-fields :input').removeClass('is-invalid');
      }
    }
    else {
      $('#cdr-webhook-fields :input').removeClass('is-invalid');
    }
    return !invalid;
  }

  function sendRequest(method, url, payload, button, on_success) {
    button.prop('disabled', true);
    $.ajax({
      type: method,
      url: url,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      data: payload === null ? undefined : JSON.stringify(payload),
      success: on_success,
      error: function(jqXHR) {
        showNotification(escapeHtml(apiErrorMessage(jqXHR)), true, 10000, false);
        if (jqXHR.responseJSON && jqXHR.responseJSON.data && jqXHR.responseJSON.data.length > 0) {
          // a failed run still reports what it did before the archive error
          loadSettings();
        }
      },
      complete: function() {
        button.prop('disabled', false);
        toggleFields();
      }
    });
  }

  $(document).ready(function() {
    if ($('#cdrSettingsForm').length === 0) {
      return;
    }
    loadSettings();

    field('CDR_ARCHIVE_ENABLED').on('change', toggleS3Fields);
    field('CDR_WEBHOOK_ENABLED').on('change', toggleWebhookFields);
    field('CDR_WEBHOOK_AUTH').on('change', toggleWebhookFields);

    $('#cdrSettingsForm').on('submit', function(ev) {
      ev.preventDefault();
      if (!validateForm()) {
        showNotification("Fix the highlighted CDR settings", true, 10000, false);
        return;
      }
      var payload = {
        CDR_RETENTION_DAYS: parseInt(field('CDR_RETENTION_DAYS').val().trim(), 10),
        CDR_ARCHIVE_ENABLED: field('CDR_ARCHIVE_ENABLED').prop('checked')
      };
      if (payload.CDR_ARCHIVE_ENABLED) {
        $.extend(payload, s3Payload());
      }
      payload.CDR_WEBHOOK_ENABLED = field('CDR_WEBHOOK_ENABLED').prop('checked');
      payload.CDR_STORE_CDR = field('CDR_STORE_CDR').prop('checked');
      if (payload.CDR_WEBHOOK_ENABLED) {
        $.extend(payload, webhookPayload());
      }
      sendRequest("PUT", SETTINGS_URL, payload, $('#cdr-save'), function(response) {
        fillForm(response.data[0]);
        showNotification("CDR settings saved", false, 10000, false);
      });
    });

    $('#cdr-test-s3').on('click', function() {
      sendRequest("POST", SETTINGS_URL + "/test-s3", s3Payload(), $(this), function(response) {
        showNotification(escapeHtml(response.msg), false, 10000, false);
      });
    });

    $('#cdr-test-webhook').on('click', function() {
      sendRequest("POST", SETTINGS_URL + "/test-webhook", webhookPayload(), $(this), function(response) {
        showNotification(escapeHtml(response.msg), false, 10000, false);
      });
    });

    $('#cdr-run-webhook').on('click', function() {
      sendRequest("POST", SETTINGS_URL + "/run-webhook", null, $(this), function(response) {
        showNotification(escapeHtml(response.msg), false, 10000, false);
        loadSettings();
      });
    });

    $('#cdr-run').on('click', function() {
      if (!confirm("Delete CDRs older than the saved retention period now?")) {
        return;
      }
      sendRequest("POST", SETTINGS_URL + "/run", null, $(this), function(response) {
        var result = response.data[0];
        var msg = response.msg;
        if (!result.skipped_locked && result.retention_days > 0) {
          msg += ": " + summarizeResult(result);
        }
        showNotification(escapeHtml(msg), false, 10000, false);
        loadSettings();
      });
    });
  });

})(window, document);
