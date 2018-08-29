function searchDIDs(search) {
  var res = [];
  var num_dids = DID_LIST.length;

  for (var i = 0; i < num_dids; i++) {
    if (DID_LIST[i].indexOf(search) === 0) {
      res.push(DID_LIST[i]);
    }
  }

  return res;
}

/* any handlers depending on DOM elems go here */
$(document).ready(function() {
  /**
   * Wrapper for initializing
   * @param parent_selector
   * @returns {aria.ListboxCombobox}
   */
  function combobox_init(parent_selector) {
    var parent = $(parent_selector);
    var arrow = parent.find('.did-combobox-arrow > span');

    /* create combobox */
    new aria.ListboxCombobox(
      parent.find('.did-combobox').get(0),
      parent.find('.did-combobox-input').get(0),
      parent.find('.did-listbox').get(0),
      searchDIDs,
      true,
      function() {
        arrow.removeClass('icon-circle-down');
        arrow.addClass('icon-circle-up');
      },
      function() {
        arrow.removeClass('icon-circle-up');
        arrow.addClass('icon-circle-down');
      }
    )
  }

  /* init the combobox's */
  combobox_init('#add .modal-body');
  combobox_init('#edit .modal-body');
});
