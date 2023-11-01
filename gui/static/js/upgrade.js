;(function(window, document) {
  'use strict';

  // throw an error if required functions not defined
  if (typeof reloadDsipRequired === "undefined") {
    throw new Error("reloadDsipRequired() is required and is not defined");
  }

  var upgrade_form = $('#upgrade_form');
  var upgrade_output_row = $('#upgrade_output_row');
  var upgrade_output = $('#upgrade_output');

  function displayUpgradeLog() {
    upgrade_form.hide();
    upgrade_output.html("");
    upgrade_output_row.show();
  }

  function streamLog() {
    var source = new EventSource("/upgrade/log");
    source.onmessage = function(event) {
      upgrade_output.append(event.data);
    };
    source.onerror = function(event) {
      source.close();
    };
  }

  function dumpLog() {
    $.ajax({
      type: "GET",
      url: "/upgrade/log",
      success: function(response, textStatus, jqXHR) {
        upgrade_output.append(response);
      }
    });
  }

  function monitorUpgrade() {
    var source = new EventSource("/upgrade/status");
    source.onmessage = function(event) {
      if (event.data === '0') {
        reloadDsipRequired(true);
      }
    };
    source.onerror = function(event) {
      source.close();
    };
  }

  $(document).ready(function() {
    $('#btnShowLog').click(function() {
      displayUpgradeLog();
      dumpLog();
    });

    upgrade_form.submit(function(e) {
      e.preventDefault();

      var formData = $(this).serialize();

      $.ajax({
        type: "POST",
        url: "/upgrade/start",
        async: true,
        data: formData,
        success: function(response, text_status, xhr) {
          showNotification("Upgrade started. See log below for more details..", 5000);
          displayUpgradeLog();
          streamLog();
          monitorUpgrade();
        },
        error: function(xhr, text_status, error_msg) {
          showNotification("Could not start upgrade: " + error_msg, true);
        }
      });
    });
  });

})(window, document);
