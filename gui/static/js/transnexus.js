;(function (window, document) {
  'use strict';

  $(document).ready(function() {
    var toggle = $('#toggleTransnexus');

    function updateToggle() {
      if (toggle.is(":checked") || toggle.prop("checked")) {
        $('#transnexusOptions').removeClass("hidden");
        $(this).val("1");
        $(this).bootstrapToggle('on');
      }
      else {
        $('#transnexusOptions').addClass("hidden");
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
