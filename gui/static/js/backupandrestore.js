$('#start-Backup').click(function() {
  $('#wait-animation').show();
  document.location.href = '/api/v1/backupandrestore/backup';
  $('#wait-animation').hide();
});

$('#restore-backup').submit(function(event) {
  event.preventDefault();
  var formData = new FormData($(this)[0]);
  $.ajax({
    url: '/api/v1/backupandrestore/restore',
    type: 'POST',
    data: formData,
    async: false,
    cache: false,
    contentType: false,
    processData: false,
    success: function(response) {
      if (response.status == "200") {
        displaymessage("<strong>Database was restored</strong>", "success");
        reloadkamrequired();
      }
      else {
        displaymessage("<strong>Database was NOT restored</strong>", "error");
      }
    }
  });

  return false;

});
