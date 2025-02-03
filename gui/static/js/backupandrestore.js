;(function(window, document) {
  'use strict';

  // throw an error if required functions not defined
  if (typeof showNotification === "undefined") {
    throw new Error("showNotification() is required and is not defined");
  }
  if (typeof reloadKamRequired === "undefined") {
    throw new Error("reloadKamRequired() is required and is not defined");
  }

  // throw an error if required globals not defined
  if (typeof API_BASE_URL === "undefined") {
    throw new Error("API_BASE_URL is required and is not defined");
  }

  /* global variables */
  var loading_spinner = $('#reloading_overlay');

  /**
   * Show a spinner while loading
   * @param isLoading {boolean}
   */
  function changeLoadingState(isLoading) {
    if (isLoading) {
      loading_spinner.removeClass('hidden');
    }
    else {
      loading_spinner.addClass('hidden');
    }
  }

  function downloadResponse(response, filename) {
    var a = document.createElement("a");
    var fp = new Blob([response], {type: 'text/plain'});
    var url = window.URL.createObjectURL(fp);
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  }

  /**
   * Get the current date / time formatted as "YYYYmmdd-HHMM"
   * @returns {string}
   */
  function getFormattedDateTime() {
    var d = new Date();
    return d.getFullYear().toString() +
      (d.getMonth() + 1).toString().padStart(2, '0') +
      d.getDate().toString().padStart(2, '0') +
      '-' +
      d.getHours().toString().padStart(2, '0') +
      d.getMinutes().toString().padStart(2, '0');
  }

  $('#start-Backup').click(function() {
    $.ajax({
      url: API_BASE_URL + 'backupandrestore/backup',
      type: 'GET',
      cache: false,
      processData: false,
      accepts: {
        json: "application/json",
        text: "application/sql"
      },
      beforeSend: function(xhr, settings) {
        changeLoadingState(true);
      },
      success: function(response, text_status, xhr) {
        showNotification("Database backup complete");
        var fname = getFormattedDateTime() + '.sql';
        downloadResponse(response, fname);
      },
      error: function(xhr, text_status, error_msg) {
	      var string = JSON.stringify(xhr.responseJSON);
	      var json_object = JSON.parse(string);
        showNotification(json_object.msg, true);
      },
      complete: function(xhr, text_status) {
        changeLoadingState(false);
      },
    });
  });

  $('#restore-backup').submit(function(event) {
    event.preventDefault();
    var formData = new FormData($(this)[0]);

    $.ajax({
      url: API_BASE_URL + 'backupandrestore/restore',
      type: 'POST',
      data: formData,
      cache: false,
      contentType: false,
      processData: false,
      beforeSend: function(xhr, settings) {
        changeLoadingState(true);
      },
      success: function(response, text_status, xhr) {
        showNotification("Database restore complete");
        reloadKamRequired(true);
      },
      error: function(xhr, text_status, error_msg) {
	      var string = JSON.stringify(xhr.responseJSON);
	      var json_object = JSON.parse(string);
        showNotification(json_object.msg, true);
      },
      complete: function(xhr, text_status) {
        changeLoadingState(false);
      },
    });

    return false;
  });

})(window, document);
