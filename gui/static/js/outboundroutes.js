;(function(window, document) {
  'use strict';

  $(document).ready(function () {
    /* data tables init */
    $('#outboundmapping').DataTable({
      "columnDefs": [
        {"orderable": true, "targets": [1, 3, 4, 5, 6, 7, 8, 9]},
        {"orderable": false, "targets": [0, 2, 10, 11]},
      ],
      "order": [[1, 'asc']]
    });

    /* validator init */
    $('#addOutboundRoutes').validator({
      custom: {
        tocheck: function ($el) {
          return $el.length > 0 && $('prefix').length > 0;
        }
      },
      errors: {
        tocheck: "You must enter a To Prefix as well.  Entering just a From prefix is not supported"
      }
    });

    /* listeners */
    $('#outboundmapping').on('click', '#open-Update', function () {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('outboundmapping');

      var ruleid = $(c).find('tr:eq(' + row_index + ') > td.ruleid').text();
      var groupid = $(c).find('tr:eq(' + row_index + ') > td.groupid').text();
      var prefix = $(c).find('tr:eq(' + row_index + ') > td.prefix').text();
      var from_prefix = $(c).find('tr:eq(' + row_index + ') > td.from_prefix').text();
      var timerec = $(c).find('tr:eq(' + row_index + ') > td.timerec').text();
      var priority = $(c).find('tr:eq(' + row_index + ') > td.priority').text();
      var routeid = $(c).find('tr:eq(' + row_index + ') > td.routeid').text();
      var gwgroupid = $(c).find('tr:eq(' + row_index + ') > td.gwgroupid').text();
      var name = $(c).find('tr:eq(' + row_index + ') > td.description').text();

      /** Clear out the modal */
      var modal_body = $('#edit .modal-body');
      modal_body.find("input.ruleid").val('');
      modal_body.find("input.groupid").val('');
      modal_body.find("input.prefix").val('');
      modal_body.find("input.from_prefix").val('');
      modal_body.find("input.timerec").val('');
      modal_body.find("input.priority").val('');
      modal_body.find("input.gwgroupid").val('');
      modal_body.find("input.name").val('');

      /* update modal fields */
      modal_body.find("input.ruleid").val(ruleid);
      modal_body.find("input.groupid").val(groupid);
      modal_body.find("input.prefix").val(prefix);
      modal_body.find("input.from_prefix").val(from_prefix);
      modal_body.find("input.timerec").val(timerec);
      modal_body.find("input.priority").val(priority);
      modal_body.find("input.name").val(name);

      /* update options selected */
      modal_body.find("select").val('');
      modal_body.find("select.gwgroupid").val(gwgroupid);
      modal_body.find("select.routeid").val(routeid);
    });

    $('#outboundmapping').on('click','#open-Delete', function () {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('outboundmapping');
      var ruleid = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();

      /* update modal fields */
      var modal_body = $('#delete .modal-body');
      modal_body.find(".ruleid").val(ruleid);
    });
  });

})(window, document);

