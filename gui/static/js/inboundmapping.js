/**
 * @namespace aria
 */
var aria = aria || {};

/**
 * @global
 * @type {Array}
 */
var DID_LIST = DID_LIST || [];

/**
 * Search DID_LIST for search_string
 * DID_LIST should be globally defined
 * @param search
 * @returns {Array}
 */
function searchDIDs(search) {
  var res = [];
  var num_dids = DID_LIST.length;

  for (var i = 0; i < num_dids; i++) {
    if (DID_LIST[i].indexOf(search.toLowerCase()) === 0) {
      res.push(DID_LIST[i]);
    }
  }
  return res;
}

/**
 * Wrapper for initializing
 * @param parent_selector
 * @returns {aria.ListboxCombobox}
 */
function comboboxInit(parent_selector) {
  var parent = $(parent_selector);
  var arrow = parent.find('.did-combobox-arrow > span');

  /* create combobox */
  new aria.ListboxCombobox(
    parent.find('.did-combobox').get(0),
    parent.find('.did-combobox-input').get(0),
    parent.find('.did-listbox').get(0),
    searchDIDs,
    false,
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

/* any handlers depending on DOM elems go here */
$(document).ready(function() {
  /* only created if we have DID's */
  if (DID_LIST.length > 0) {
    /* init the combobox's */
    comboboxInit('#add .modal-body');
    comboboxInit('#edit .modal-body');
  }

  /* init datatable */
  $('#inboundmapping').DataTable({
    "columnDefs": [
      { "orderable": true, "targets": [1,2,3,4,5] },
      { "orderable": false, "targets": [0,6,7] },
    ],
    "order": [[ 1, 'asc' ]]
  });

  /* make sure we don't have duplicate selects */
  var add_modal = $('#add .modal-body');
  var edit_modal = $('#edit .modal-body');
  add_modal.find("select").change(function() {
    var options = add_modal.find("select").not(this).find("option").get();
    for (var i = 0; i < options.length; i++) {
      options[i].value === $(this).val() ? $(options[i]).attr('disabled', true) : $(options[i]).removeAttr('disabled')
    }
  });
  edit_modal.find("select").change(function() {
    var options = add_modal.find("select").not(this).find("option").get();
    for (var i = 0; i < options.length; i++) {
      options[i].value === $(this).val() ? $(options[i]).attr('disabled', true) : $(options[i]).removeAttr('disabled')
    }
  });
});
