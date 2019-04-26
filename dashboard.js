function getKamailioStats(elmnt) {
  //elmnt.style.backgroundColor = "red";
  //elmnt.style.borderColor = "red"
  var msg_bar = $(".message-bar");
  var reload_button = $('#reloadkam');


  $.ajax({
    type: "GET",
    url: "/v1/kamailio/stats",
    dataType: "json",
    success: function(msg) {
      if (msg.status === 1) {
        msg_bar.addClass("alert alert-success");
        msg_bar.html("<strong>Success!</strong> Kamailio was reloaded successfully!");
        reload_button.removeClass('btn-warning');
        reload_button.addClass('btn-primary');
      }
      else {
        msg_bar.addClass("alert alert-danger");
        msg_bar.html("<strong>Failed!</strong> Kamailio was NOT reloaded successfully!");
      }

      msg_bar.show();
      msg_bar.slideUp(3000, "linear");
      //elmnt.style.backgroundColor = "#337ab7";
      //elmnt.style.borderColor = "#2e6da4";
    }
  });
}

