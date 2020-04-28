/* Initialize variables or perform actions as needed */
$(document).ready(function() {
  domain = $('#testConnectivity').val()
  runTests(domain)
});

$('#testConnectivity').click(function(){
  domain = $('#testConnectivity').val()
  runTests(domain);
}
);

/* Update the display with the status of the tests */
function updateConnectivtyStatus(msg) {

  $("#hostname_check").removeClass();
  $("#tls_check").removeClass();
  $("#option_check").removeClass();

  //Hostname Check
  if (msg.hostname_check == true)
  {
    $("#hostname_check").addClass("glyphicon glyphicon-ok");
    $("#hostname_check").css("color","green");
  }
  else {
    $("#hostname_check").addClass("glyphicon glyphicon-remove");
    $("#hostname_check").css("color","red");
  }

  if (msg.tls_check.tls_cert_valid == true)
  {
    $("#tls_check").addClass("glyphicon glyphicon-ok");
    $("#tls_check").css("color","green");
  }
  else {
    $("#tls_check").addClass("glyphicon glyphicon-remove");
    $("#tls_check").css("color","red");
  }

  //Option Check
  if (msg.option_check == true)
  {
    $("#option_check").addClass("glyphicon glyphicon-ok");
    $("#option_check").css("color","green");
  }
  else {
    $("#option_check").addClass("glyphicon glyphicon-remove");
    $("#option_check").css("color","red");
  }


}

/* Set the width of the sidebar to 250px (show it) */
function openNav() {
  document.getElementById("configurationPanel").style.width = "auto";
}

/* Set the width of the sidebar to 0 (hide it) */
function closeNav() {
  document.getElementById("configurationPanel").style.width = "0";
}

function runTests() {

  //Disable Test Connectivity Button
  $('#testConnectivity').prop('disabled', true);

  //Run Test using API
  $.ajax({
    type: "GET",
    url: "/api/v1/domains/msteams/test/" + domain,
    dataType: "json",
    contentType: "application/json; charset=utf-8",
    success: function(msg) {
      // Update the display
      updateConnectivtyStatus(msg)
    }
  });

  //Enable Test Connectivity Button
  $('#testConnectivity').prop('disabled', false);
}
