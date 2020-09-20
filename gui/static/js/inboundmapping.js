;(function(window, document) {
  'use strict';

  /**
   * @global window scope
   * @namespace aria
   */
  var aria = aria || {};

  /**
   * @global script scope
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
        {"orderable": true, "targets": [1, 2, 3, 4, 5]},
        {"orderable": false, "targets": [0, 6, 7]},
      ],
      "order": [[1, 'asc']]
    });

    $('#open-Add').click(function() {
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
      modal_body.find("select").val('');

      /* reset toggle buttons */
      modal_body.find("input.toggle-hardfwd").bootstrapToggle('off');
      modal_body.find("input.toggle-failfwd").bootstrapToggle('off');
    });

    $('#inboundmapping').on('click', '#open-Update', function() {
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
      modal_body.find("select").val('');
      modal_body.find("select.gwgroupid").val(gwgroupid);
      modal_body.find("select.hf_gwgroupid").val(hf_gwgroupid);
      modal_body.find("select.ff_gwgroupid").val(ff_gwgroupid);

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

    $('#inboundmapping').on('click', '#open-Delete', function() {
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

    /* listener for hard forward toggle */
    $('.modal-body .toggle-hardfwd').change(function() {
      var modal = $(this).closest('div.modal');
      var modal_body = modal.find('.modal-body');

      if ($(this).is(":checked") || $(this).prop("checked")) {
        modal_body.find('.hardfwd-options').removeClass("hidden");
        modal_body.find('.hardfwd_enabled').val(1);
      }
      else {
        modal_body.find('.hardfwd-options').addClass("hidden");
        modal_body.find('.hardfwd_enabled').val(0);
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

})(window, document);
