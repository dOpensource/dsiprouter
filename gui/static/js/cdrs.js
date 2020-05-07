;(function (window, document) {
  'use strict';

  // globals for this scope
  var epgroup_select = $("#endpointgroups");
  var loading_spinner = $('#loading-spinner');

  /**
   * Show a spinner while loading
   * @param isLoading {boolean}
   */
  function changeLoadingState(isLoading) {
    if (isLoading) {
      loading_spinner.removeClass('hidden');
    }
    else {
      loading_spinner.addClass('hidden');
    }
  }

  function getFilteredCdrIds() {
    return $('#cdrs').DataTable().columns( { search: 'applied' } ).data()[0];
  }

  function loadCDRDataTable(gwgroupid) {
    changeLoadingState(true);

    // load CDR data
    if ($.fn.dataTable.isDataTable('#cdrs')) {
      var table = $('#cdrs').DataTable();
      // Clear the contents of the table
      table.clear();
      table.draw();
      table.ajax.url("/api/v1/cdrs/endpointgroups/" + gwgroupid);
      table.ajax.reload();
    }
    // datatable init
    else {
      $('#cdrs').DataTable({
        "ajax": {
          "url": "/api/v1/cdrs/endpointgroups/" + gwgroupid,
          "dataSrc": "cdrs"
        },
        "columns": [
          {"data": "cdr_id"},
          {"data": "gwid"},
          {"data": "call_start_time"},
          {"data": "calltype"},
          {"data": "subscriber"},
          {"data": "to_num"},
          {"data": "from_num"},
          {"data": "src_ip"},
          {"data": "dst_domain"},
          {"data": "duration"},
          {"data": "sip_call_id"}
          //{ "data": "gwlist", visible: false },
        ],
        "order": [],
        "pageLength": 100
      });
    }

    changeLoadingState(false);
  }

  $(document).ready(function () {
    // get endpoint group data
    $.ajax({
      type: "GET",
      url: "/api/v1/endpointgroups",
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function (msg) {
        for (var i = 0; i < msg.endpointgroups.length; i++) {
          epgroup_select.append("<option value='" + msg.endpointgroups[i].gwgroupid + "'>" + msg.endpointgroups[i].name + "</option>");
        }
      }
    })

    // change table when endpoint group selected
    epgroup_select.change(function () {
      loadCDRDataTable($("#endpointgroups option:selected").val());
    })

    $('#downloadCDR').click(function () {
      var gwgroupid = $("#endpointgroups").val();
      document.location.href = '/api/v1/cdrs/endpointgroups/' + gwgroupid + '?type=csv&filter=' + getFilteredCdrIds().join(',');
    });
  });
})(window, document);
