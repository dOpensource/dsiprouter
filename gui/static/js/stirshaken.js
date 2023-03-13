;(function (window, document) {
  'use strict';

  $(document).ready(function() {
    var toggle = $('#toggleStirShaken');

    function updateToggle() {
      if (toggle.is(":checked") || toggle.prop("checked")) {
        $('#stirShakenOptions').removeClass("hidden");
        $(this).val("1");
        $(this).bootstrapToggle('on');
      }
      else {
        $('#stirShakenOptions').addClass("hidden");
        $(this).val("0");
        $(this).bootstrapToggle('off');
      }
    }

    /* update toggle on page load */
    updateToggle();
    /* listener for toggle changes */
    toggle.change(updateToggle);
  });

})(window, document);
