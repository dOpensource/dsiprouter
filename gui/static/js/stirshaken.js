;(function (window, document) {
  'use strict';

  $(document).ready(function() {
    var toggle = $('#toggleStirShaken');

    function updateToggle() {
      if (toggle.is(":checked") || toggle.prop("checked")) {
        $('#stirShakenOptions').removeClass("hidden");
        toggle.val("1");
      }
      else {
        $('#stirShakenOptions').addClass("hidden");
        toggle.val("0");
      }
    }

    /* update toggle on page load */
    updateToggle();
    /* listener for toggle changes */
    toggle.change(updateToggle);
  });

})(window, document);
