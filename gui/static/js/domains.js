;(function(window, document) {
  'use strict';

  function processDomainType(value) {
    var modal_body = $('.modal-body');

    if (value == "msteams-nosub") {
      //console.log("Clicked on authtype " + value);
      modal_body.find(".domain_name").attr('disabled', true);
      modal_body.find(".pbx_list").attr('disabled', true);
      modal_body.find(".notes").attr('disabled', true);
      modal_body.find(":submit").attr('disabled', true);
      //modal_body.find(":submit").attr('disabled',true);
    }
    else {
      modal_body.find(".domain_name").attr('disabled', false);
      modal_body.find(".pbx_list").attr('disabled', false);
      modal_body.find(".notes").attr('disabled', false);
      modal_body.find(":submit").attr('disabled', false);

    }
  }

  $(document).ready(function() {
    // datatable init
    $('#domains').DataTable({
      "columnDefs": [
        {"orderable": true, "targets": [1, 2, 3, 4, 5, 6, 7]},
        {"orderable": false, "targets": [0, 8, 9]},
      ],
      "order": [[1, 'asc']]
    });

    // Resets the Add Modal
    $('#open-DomainAdd').click(function() {
      /** Clear out and reset the modal */
      var modal_body = $('#add .modal-body');
      modal_body.find(".domain_name").attr('disabled', false);
      modal_body.find(".pbx_list").attr('disabled', false);
      modal_body.find(".notes").attr('disabled', false);
      modal_body.find(":submit").attr('disabled', false);
      modal_body.find(".domain_id").val('');
      modal_body.find(".domain_name").val('');
      modal_body.find(".domain_type").val('');
      modal_body.find(".pbx_name").val('');
      modal_body.find(".pbx_list").val('');
      modal_body.find(".notes").val('');
      modal_body.find('.authtype').val([]);
      modal_body.find('.authtype').val("");

    });

    // Updates the modal with the values from the endpointgroup API
    $('#domains #open-Update').click(function() {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('domains');
      var domain_id = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
      var domain_name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();
      var domain_type = $(c).find('tr:eq(' + row_index + ') td:eq(3)').text();
      var pbx_name = $(c).find('tr:eq(' + row_index + ') td:eq(4)').text();
      var authtype = $(c).find('tr:eq(' + row_index + ') td:eq(5)').text();
      var pbx_list = $(c).find('tr:eq(' + row_index + ') td:eq(6)').text();
      var notes = $(c).find('tr:eq(' + row_index + ') td:eq(7)').text();


      /** Clear out and reset the modal */
      var modal_body = $('#edit .modal-body');
      modal_body.find(".domain_name").attr('disabled', false);
      modal_body.find(".pbx_list").attr('disabled', false);
      modal_body.find(".notes").attr('disabled', false);
      modal_body.find(":submit").attr('disabled', false);
      modal_body.find(".domain_id").val('');
      modal_body.find(".domain_name").val('');
      modal_body.find(".domain_type").val('');
      modal_body.find(".pbx_name").val('');
      modal_body.find(".pbx_list").val('');
      modal_body.find(".notes").val('');
      modal_body.find('.authtype').val([]);
      modal_body.find('.authtype').val("");

      /* update modal fields */
      modal_body.find(".domain_id").val(domain_id);
      modal_body.find(".domain_name").val(domain_name);
      modal_body.find(".domain_type").val(domain_type);
      modal_body.find(".pbx_name").val(pbx_name);
      modal_body.find(".pbx_list").val(pbx_list);
      modal_body.find(".notes").val(notes);

      if (authtype !== "") {
        /* Set the radio button if authtype is given */
        //modal_body.find('.authtype option[value="' + authtype + '"]').attr('selected', 'selected').trigger("change");
        modal_body.find('.authtype').val(authtype)
      }
    });

    // Updates the modal with domain to be deleted
    $('#domains #open-Delete').click(function() {
      var row_index = $(this).parent().parent().parent().index() + 1;
      var c = document.getElementById('domains');
      var domain_id = $(c).find('tr:eq(' + row_index + ') td:eq(1)').text();
      var domain_name = $(c).find('tr:eq(' + row_index + ') td:eq(2)').text();

      /* update modal fields */
      var modal_body = $('#delete .modal-body');
      modal_body.find(".domain_id").val(domain_id);
      modal_body.find(".domain_name").val(domain_name);
    });

   $('#add .authtype').change(function() {
      	var modal_body = $('#add .modal-body');
        var type = modal_body.find('.authtype').val();
   	
	processDomainType(type);
   });
   
  $('#edit .authtype').change(function() {
      	var modal_body = $('#edit .modal-body');
        var type = modal_body.find('.authtype').val();
   	
	processDomainType(type);
   });

  });
})(window, document);
