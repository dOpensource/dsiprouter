;(function (window, document) {
  'use strict';

  $(document).ready(function() {
    /* listener for TransNexus toggle */
    $('#toggleTransnexus').change(function () {
      if ($(this).is(":checked") || $(this).prop("checked")) {
        $('#transnexusOptions').removeClass("hidden");
        $(this).val("1");
        $(this).bootstrapToggle('on');
      }
      else {
        $('#transnexusOptions').addClass("hidden");
        $(this).val("0");
        $(this).bootstrapToggle('off');
      }
    });
  });

})(window, document);
