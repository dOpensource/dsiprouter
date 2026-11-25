;(function (window, document) {
  'use strict';

  // throw an error if required globals not defined
  if (typeof API_BASE_URL === "undefined") {
    throw new Error("API_BASE_URL is required and is not defined");
  }
  if (typeof delayedCallback === "undefined" || typeof throttledCallback === "undefined") {
    throw new Error("delayedCallback() and throttledCallback() are required and are not defined");
  }

  // globals for this script
  var epgroup_select = $("#endpointgroups");
  var loading_spinner = $('#loading-spinner');
  var showallcalls_inp = $('#toggle_completed_calls');
  var cdr_table = null;

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
    var value = $('#cdrs').DataTable().columns( { search: 'applied' } ).data()[0];
    // Check if values were selected using the search  field. 
    if (value != ",") {
    	return value;
    }
    else {
	    return '';
    }
  }

  /**
   * Parse a CDR call_start_time ("YYYY-MM-DD HH:MM:SS", UTC) into epoch ms
   * @param dt {string}
   * @returns {number} epoch ms or NaN
   */
  function parseCallStart(dt) {
    if (typeof dt !== "string") {
      return NaN;
    }
    var ms = Date.parse(dt.replace(" ", "T") + "Z");
    return isNaN(ms) ? Date.parse(dt) : ms;
  }

  /**
   * Render the Call ID as a link to the call in Homer (opens in a new tab)
   * Format: https://HOMER_HEP_HOST/?call_id=<call_id>&from=<start>&to=<start + duration>
   */
  function renderCallId(data, type, row) {
    if (type !== "display" || !data) {
      return data;
    }
    var escaped = $("<div>").text(data).html();
    var from = parseCallStart(row.call_start_time);
    if (!window.HOMER_HEP_HOST || isNaN(from)) {
      return escaped;
    }
    var duration = parseInt(row.call_duration, 10);
    // zero-length (failed) calls: give Homer a 5 minute window
    var to = from + (isNaN(duration) || duration <= 0 ? 5 * 60 * 1000 : duration * 1000);
    // start the Homer window 60 seconds before the call start
    var url = "https://" + window.HOMER_HEP_HOST + "/?call_id=" + encodeURIComponent(data) +
      "&from=" + (from - 60 * 1000) + "&to=" + to;
    return '<a href="' + url + '" target="_blank" rel="noopener noreferrer">' + escaped + '</a>';
  }

  function loadCDRDataTable(gwgroupid) {
    changeLoadingState(true);

    // load CDR data
    if ($.fn.dataTable.isDataTable(cdr_table)) {
      // Clear the contents of the table
      // cdr_table.clear();
      // cdr_table.draw();
      cdr_table.ajax.url(API_BASE_URL + "cdrs/endpointgroups/" + gwgroupid);
      cdr_table.ajax.reload();
    }
    // datatable init
    else {
      cdr_table = $('#cdrs').DataTable({
        "pagingType": "full_numbers",
        "processing": false,
        "serverSide": true,
        "ajax": {
          "url": API_BASE_URL + "cdrs/endpointgroups/" + gwgroupid,
          "data": function (d) {
            d.nonCompletedCalls = showallcalls_inp.val() === '1';
          },
          "dataFilter": function (data) {
            if (data) {
              var json = jQuery.parseJSON(data);
              json.recordsTotal = json.total_rows;
              json.recordsFiltered = json.filtered_rows;
              return JSON.stringify(json);
            }

            return JSON.stringify({
              data: [],
              recordsTotal: 0,
              recordsFiltered: 0
            });
          }
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
          {"data": "call_id", "orderable": false, "render": renderCallId}
        ],
        "order": [[1, 'desc']],
        "pageLength": 100,
        // make searchbox trigger less often
        // very important for intensive serverside queries
        "searchDelay": 1000,
      });

      // skip searchbox delay when pressing enter
      // we throttle this in case enter is held down
      // ignored if fired without changing the search text
      var searchbox = $(cdr_table.table().container()).find('input[type="search"]');
      var throttledEnter = throttledCallback(function(ev) {
        if (this.value === cdr_table.search()) {
          ev.preventDefault();
          return;
        }
        cdr_table.search(this.value).draw();
      }, 200);
      searchbox.on('keydown', function(ev) {
        if (ev.key === 'Enter') {
          throttledEnter.call(this, ev);
        }
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

    // default is enabled (bootstrap5-toggle auto-inits this visible checkbox on
    // window.load; set the checkbox state + fire change rather than calling the
    // removed jQuery .bootstrapToggle() plugin)
    showallcalls_inp.prop('checked', true).val(1).trigger('change');

    /* listener for completed calls toggle */
    showallcalls_inp.change(function() {
      var self = $(this);

      if (self.is(":checked") || self.prop("checked")) {
        self.val(1);
      }
      else {
        self.val(0);
      }
      loadCDRDataTable(epgroup_select.find('option:selected').val());
    });

    // change table when endpoint group selected
    epgroup_select.change(function () {
      loadCDRDataTable(epgroup_select.find('option:selected').val());
    })

    $('#downloadCDR').click(function () {
      var gwgroupid = $("#endpointgroups").val();
      window.location.href = API_BASE_URL + 'cdrs/endpointgroups/' + gwgroupid + '?type=csv&filter=' + getFilteredCdrIds().join(',');
    });

    
    // reload table when the refresh button is clicked
    $('#refreshCDR').click(function () {
      loadCDRDataTable(epgroup_select.find('option:selected').val());
    });
  });

})(window, document);
