;(function(window, document) {
  'use strict';

  function getKamailioStats(elem) {
    $.ajax({
      type: "GET",
      url: "/api/v1/kamailio/stats",
      dataType: "json",
      success: function(response, text_status, xhr) {
        var stats = response.data[0];
        // set defaults if bad response
        stats.current = stats.current !== undefined ? stats.current : 0;
        stats.waiting = stats.waiting !== undefined ? stats.waiting : 0;
        stats.total = stats.total !== undefined ? stats.total : 0;
        $("#dashboard_current_calls").text(stats.current);
        $("#dashboard_calls_inqueue").text(stats.waiting);
        $("#dashboard_total_calls_processed").text(stats.total);
      }
    });
  }

  $(document).ready(function() {
    getKamailioStats();
  });

})(window, document);
