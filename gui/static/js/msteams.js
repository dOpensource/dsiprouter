;(function(window, document) {
  'use strict';

  /* Update the display with the status of the tests */
  function updateConnectivtyStatus(msg) {
    var hostcheck_obj = $("#hostname_check");
    var tlscheck_obj = $("#tls_check");
    var tlscheckrow_obj = $("#tls_check_row");
    var optioncheck_obj = $("#option_check");
    var tlscheck_msg = "";

    hostcheck_obj.removeClass();
    tlscheck_obj.removeClass();
    optioncheck_obj.removeClass();

    //Hostname Check
    if (msg.hostname_check == true) {
      hostcheck_obj.addClass("glyphicon glyphicon-ok");
      hostcheck_obj.css("color", "green");
    }
    else {
      hostcheck_obj.addClass("glyphicon glyphicon-remove");
      hostcheck_obj.css("color", "red");
    }

    if (msg.tls_check.tls_cert_valid == true) {
      tlscheck_obj.addClass("glyphicon glyphicon-ok");
      tlscheck_obj.css("color", "green");
    }
    else {
      tlscheck_obj.addClass("glyphicon glyphicon-remove");
      tlscheck_obj.css("color", "red");
      if (msg.tls_check.tls_error.length > 0) {
        tlscheck_msg = msg.tls_check.tls_error;
      }
      else {
        tlscheck_msg = "Cert commonname doesn't match the domain:" + JSON.stringify(msg.tls_check.tls_cert_details);
      }

      tlscheckrow_obj.tooltip({
        'title': tlscheck_msg,
        'placement': 'right',
        'trigger': 'manual',
        'tooltipClass': 'tooltipclass'
      });
      tlscheckrow_obj.tooltip('show');
    }

    //Option Check
    if (msg.option_check == true) {
      optioncheck_obj.addClass("glyphicon glyphicon-ok");
      optioncheck_obj.css("color", "green");
    }
    else {
      optioncheck_obj.addClass("glyphicon glyphicon-remove");
      optioncheck_obj.css("color", "red");
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
    var testconn_obj = $('#testConnectivity');
    var domain = testconn_obj.val();

    //Disable Test Connectivity Button
    testconn_obj.prop('disabled', true);

    //Run Test using API
    $.ajax({
      type: "GET",
      url: "/api/v1/domains/msteams/test/" + domain,
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function(response, text_status, xhr) {
        // Update the display
        updateConnectivtyStatus(response.data[0])
      }
    });

    //Enable Test Connectivity Button
    testconn_obj.prop('disabled', false);
  }

  /* once DOM is ready init variables and listeners */
  $(document).ready(function() {
    runTests();
    $('#testConnectivity').click(function() {
      runTests();
    });
  });

})(window, document);
