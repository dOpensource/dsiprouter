;(function(window, document) {
  'use strict';

  // throw an error if required functions not defined
  if (typeof showNotification === "undefined") {
    throw new Error("showNotification() is required and is not defined");
  }

  // throw an error if required globals not defined
  if (typeof API_BASE_URL === "undefined") {
    throw new Error("API_BASE_URL is required and is not defined");
  }

  $('#start-Backup').click(function() {
    var wait_animation = $('#wait-animation');
    wait_animation.show();
    window.location.href = API_BASE_URL + 'backupandrestore/backup';
    wait_animation.hide();
  });

  $('#restore-backup').submit(function(event) {
    event.preventDefault();
    var formData = new FormData($(this)[0]);

    $.ajax({
      url: API_BASE_URL + 'backupandrestore/restore',
      type: 'POST',
      data: formData,
      async: false,
      cache: false,
      contentType: false,
      processData: false,
      success: function(response, text_status, xhr) {
        showNotification("Database was restored");
      },
      error: function(xhr, text_status, error_msg) {
        showNotification("Database was NOT restored", true);
      }
    });

    return false;
  });

})(window, document);
