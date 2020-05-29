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
      success: function(response) {
        if (response.status == "200") {
          showNotification("Database was restored");
          reloadkamrequired();
        }
        else {
          showNotification("Database was NOT restored", true);
        }
      }
    });

    return false;
  });

})(window, document);
