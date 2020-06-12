;(function (window, document) {
  'use strict';

  // throw an error if required globals not defined
  if (typeof API_BASE_URL === "undefined") {
    throw new Error("API_BASE_URL is required and is not defined");
  }

  // globals for this script
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
      table.ajax.url(API_BASE_URL + "cdrs/endpointgroups/" + gwgroupid);
      table.ajax.reload();
    }
    // datatable init
    else {
      $('#cdrs').DataTable({
        "ajax": {
          "url": API_BASE_URL + "cdrs/endpointgroups/" + gwgroupid,
          "dataSrc": "cdrs"
        },
        "columns": [
          {"data": "cdr_id", "orderable": false},
          {"data": "call_start_time"},
          {"data": "call_duration"},
          {"data": "call_direction"},
          {"data": "src_gwgroupid", "visible": false, "searchable": false},
          {"data": "src_gwgroupname"},
          {"data": "dst_gwgroupid", "visible": false, "searchable": false},
          {"data": "dst_gwgroupname"},
          {"data": "src_username"},
          {"data": "dst_username"},
          {"data": "src_address"},
          {"data": "dst_address"},
          {"data": "call_id", "orderable": false}
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
      url: API_BASE_URL + "endpointgroups",
      dataType: "json",
      contentType: "application/json; charset=utf-8",
      success: function (response, textStatus, jqXHR) {
        for (var i = 0; i < response.data.length; i++) {
          epgroup_select.append("<option value='" + response.data[i].gwgroupid + "'>" + response.data[i].name + "</option>");
        }
      }
    })

    // change table when endpoint group selected
    epgroup_select.change(function () {
      loadCDRDataTable($("#endpointgroups option:selected").val());
    })

    $('#downloadCDR').click(function () {
      var gwgroupid = $("#endpointgroups").val();
      window.location.href = API_BASE_URL + 'cdrs/endpointgroups/' + gwgroupid + '?type=csv&filter=' + getFilteredCdrIds().join(',');
    });
  });

})(window, document);
