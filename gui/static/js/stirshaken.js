;(function (window, document) {
  'use strict';

  $(document).ready(function() {
    /* listener for stir chaken toggle */
    $('#toggleStirShaken').change(function () {
      if ($(this).is(":checked") || $(this).prop("checked")) {
        $('#stirShakenOptions').removeClass("hidden");
        $(this).val("1");
        $(this).bootstrapToggle('on');
      }
      else {
        $('#stirShakenOptions').addClass("hidden");
        $(this).val("0");
        $(this).bootstrapToggle('off');
      }
    });
  });

})(window, document);
