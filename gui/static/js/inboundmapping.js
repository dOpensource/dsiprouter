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
 * Will load function from main.js if avilable
 * Otherwise will do nothing and print error to console
 * @function
 */
var toggleElemDisabled = toggleElemDisabled || function(a,b) {
  console.err("toggleElemDisabled() not defined, main.js must be loaded first");
};

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

  $('#open-Add').click(function(){
    /** Clear out the modal */
    var modal_body = $('#add .modal-body');
    modal_body.find("input.ruleid").val('');
    modal_body.find("input.prefix").val('');
    modal_body.find("input.rulename").val('');
    modal_body.find("input.hf_ruleid").val('');
    modal_body.find("input.hf_groupid").val('');
    modal_body.find("input.hf_fwddid").val('');
    modal_body.find("input.ff_ruleid").val('');
    modal_body.find("input.ff_groupid").val('');
    modal_body.find("input.ff_fwddid").val('');

    /* reset options selected */
    modal_body.find("select").prop('selectedIndex', 0);

    /* reset toggle buttons */
    modal_body.find("input.toggle-hardfwd").bootstrapToggle('off');
    modal_body.find("input.toggle-failfwd").bootstrapToggle('off');
  });

  $('#inboundmapping #open-Update').click(function() {
    var row_index = $(this).parent().parent().parent().index() + 1;
    var c = document.getElementById('inboundmapping');
    var ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
    var prefix = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
    var gwgroupid = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
    var rulename = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
    var hf_ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(9)').text();
    var hf_groupid = $(c).find('tr:eq(' + row_index + ') td:eq(10)').text();
    var hf_gwgroupid = $(c).find('tr:eq(' + row_index + ') td:eq(11)').text();
    var hf_fwddid = $(c).find('tr:eq(' + row_index + ') td:eq(12)').text();
    var ff_ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(13)').text();
    var ff_groupid = $(c).find('tr:eq(' + row_index + ') td:eq(14)').text();
    var ff_gwgroupid = $(c).find('tr:eq(' + row_index + ') td:eq(15)').text();
    var ff_fwddid = $(c).find('tr:eq(' + row_index + ') td:eq(16)').text();

    /** Clear out the modal */
    var modal_body = $('#edit .modal-body');
    modal_body.find("input.ruleid").val('');
    modal_body.find("input.prefix").val('');
    modal_body.find("input.rulename").val('');
    modal_body.find("input.hf_ruleid").val('');
    modal_body.find("input.hf_groupid").val('');
    modal_body.find("input.hf_fwddid").val('');
    modal_body.find("input.ff_ruleid").val('');
    modal_body.find("input.ff_groupid").val('');
    modal_body.find("input.ff_fwddid").val('');

    /* update modal fields */
    modal_body.find("input.ruleid").val(ruleid);
    modal_body.find("input.prefix").val(prefix);
    modal_body.find("input.rulename").val(rulename);
    modal_body.find("input.hf_ruleid").val(hf_ruleid);
    modal_body.find("input.hf_groupid").val(hf_groupid);
    modal_body.find("input.hf_fwddid").val(hf_fwddid);
    modal_body.find("input.ff_ruleid").val(ff_ruleid);
    modal_body.find("input.ff_groupid").val(ff_groupid);
    modal_body.find("input.ff_fwddid").val(ff_fwddid);

    /* update options selected */
    var i = 0;
    var gwgroup_options = modal_body.find("select.gwgroupid > option").get();
    for (i = 0; i < gwgroup_options.length; i++) {
      if (gwgroupid === gwgroup_options[i].value) {
        $(gwgroup_options[i]).attr('selected', true);
        break;
      }
    }
    var hf_gwgroup_options = modal_body.find("select.hf_gwgroupid > option").get();
    for (i = 0; i < hf_gwgroup_options.length; i++) {
      if (hf_gwgroupid === hf_gwgroup_options[i].value) {
        $(hf_gwgroup_options[i]).attr('selected', true);
        break;
      }
    }
    var ff_gwgroup_options = modal_body.find("select.ff_gwgroupid > option").get();
    for (i = 0; i < ff_gwgroup_options.length; i++) {
      if (ff_gwgroupid === ff_gwgroup_options[i].value) {
        $(ff_gwgroup_options[i]).attr('selected', true);
        break;
      }
    }

    /* update toggle buttons */
    if (hf_ruleid.length > 0) {
      modal_body.find("input.toggle-hardfwd").bootstrapToggle('on');
    }
    else {
      modal_body.find("input.toggle-hardfwd").bootstrapToggle('off');
    }

    if (ff_ruleid.length > 0) {
      modal_body.find("input.toggle-failfwd").bootstrapToggle('on');
    }
    else {
      modal_body.find("input.toggle-failfwd").bootstrapToggle('off');
    }
  });

  $('#inboundmapping #open-Delete').click(function() {
    var row_index = $(this).parent().parent().parent().index() + 1;
    var c = document.getElementById('inboundmapping');
    var ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
    var hf_ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(9)').text();
    var hf_groupid = $(c).find('tr:eq(' + row_index + ') td:eq(10)').text();
    var ff_ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(13)').text();
    var ff_groupid = $(c).find('tr:eq(' + row_index + ') td:eq(14)').text();

    /* update modal fields */
    var modal_body = $('#delete .modal-body');
    modal_body.find("input.ruleid").val(ruleid);
    modal_body.find("input.hf_ruleid").val(hf_ruleid);
    modal_body.find("input.hf_groupid").val(hf_groupid);
    modal_body.find("input.ff_ruleid").val(ff_ruleid);
    modal_body.find("input.ff_groupid").val(ff_groupid);
  });

  /* make sure we don't have duplicate selects */
  var add_modal = $('#add .modal-body');
   add_modal.find("select").change(function() {
    /* we don't care if there are duplicate selects of the default value */
    if (this.selectedIndex !== 0) {
      var options = add_modal.find("select").not(this).find("option").get();
      for (var i = 0; i < options.length; i++) {
        options[i].value === $(this).val() ? toggleElemDisabled($(options[i]), true, true) : toggleElemDisabled($(options[i]), false, true)
      }
    }
  });
  var edit_modal = $('#edit .modal-body');
  edit_modal.find("select").change(function() {
    /* we don't care if there are duplicate selects of the default value */
    if (this.selectedIndex !== 0) {
      var options = edit_modal.find("select").not(this).find("option").get();
      for (var i = 0; i < options.length; i++) {
        options[i].value === $(this).val() ? toggleElemDisabled($(options[i]), true, true) : toggleElemDisabled($(options[i]), false, true)
      }
    }
  });

  /* listener for hard forward toggle */
  $('.modal-body .toggle-hardfwd').change(function() {
    var modal = $(this).closest('div.modal');
    var modal_body = modal.find('.modal-body');

    if ($(this).is(":checked") || $(this).prop("checked")) {
      modal_body.find('.hardfwd-options').removeClass("hidden");
      modal_body.find('.hardfwd_enabled').val(1);
      modal_body.find('select.gwgroupid').prop('selectedIndex', 0);
      toggleElemDisabled(modal_body.find('select.gwgroupid'), true);
    }
    else {
      modal_body.find('.hardfwd-options').addClass("hidden");
      modal_body.find('.hardfwd_enabled').val(0);
      toggleElemDisabled(modal_body.find('select.gwgroupid'), false);
    }
  });

  /* listener for failover forward toggle */
  $('.modal-body .toggle-failfwd').change(function() {
    var modal = $(this).closest('div.modal');
    var modal_body = modal.find('.modal-body');

    if ($(this).is(":checked") || $(this).prop("checked")) {
      modal_body.find('.failfwd-options').removeClass("hidden");
      modal_body.find('.failfwd_enabled').val(1);
    }
    else {
      modal_body.find('.failfwd-options').addClass("hidden");
      modal_body.find('.failfwd_enabled').val(0);
    }
  });
});
