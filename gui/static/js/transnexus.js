;(function (window, document) {
  'use strict';

  function updateToggle(toggle_node, settings_node) {
    if (toggle_node.is(":checked") || toggle_node.prop("checked")) {
      settings_node.removeClass("hidden");
      toggle_node.val("1");
      toggle_node.bootstrapToggle('on');
    }
    else {
      settings_node.addClass("hidden");
      toggle_node.val("0");
      toggle_node.bootstrapToggle('off');
    }
  }

  $(document).ready(function() {
    var auth_toggle = $('#toggle_auth_settings');
    var auth_settings = $('#authservice_settings');
    var verify_toggle = $('#toggle_verify_settings');
    var verify_settings = $('#verifyservice_settings');

    /* update toggle on page load */
    updateToggle(auth_toggle, auth_settings);
    updateToggle(verify_toggle, verify_settings);
    /* listener for toggle changes */
    auth_toggle.change(function() {
      updateToggle(auth_toggle, auth_settings);
    });
    verify_toggle.change(function() {
      updateToggle(verify_toggle, verify_settings);
    });
  });

})(window, document);
