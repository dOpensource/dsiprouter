;(function(window, document) {
  'use strict';

  function getKamailioStats(elem) {
    $.ajax({
      type: "GET",
      url: "/api/v1/kamailio/stats",
      dataType: "json",
      success: function(msg) {
        document.getElementById("dashboard_current_calls").innerHTML = msg.result.current;
        document.getElementById("dashboard_calls_inqueue").innerHTML = msg.result.waiting;
        document.getElementById("dashboard_total_calls_processed").innerHTML = msg.result.total;
      }
    });
  }

  $(document).ready(function() {
    getKamailioStats();
  });

})(window, document);
