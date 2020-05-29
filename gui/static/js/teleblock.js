;(function (window, document) {
  'use strict';

  $(document).ready(function() {
    /* listener for teleblock toggle */
    $('#toggleTeleblock').change(function () {
      if ($(this).is(":checked") || $(this).prop("checked")) {
        $('#teleblockOptions').removeClass("hidden");
        $(this).val("1");
        $(this).bootstrapToggle('on');
      }
      else {
        $('#teleblockOptions').addClass("hidden");
        $(this).val("0");
        $(this).bootstrapToggle('off');
      }
    });
  });

})(window, document);
