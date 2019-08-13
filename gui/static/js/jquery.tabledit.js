/**
 * @description Inline editor for HTML tables compatible with Bootstrap
 * @version     1.2.3
 * @author      Celso Marques
 * @copyright   Copyright (c) 2015 Celso Marques
 * @link        https://github.com/markcell/jQuery-Tabledit
 */

/**
 * The modified version
 * @version     1.2.9 DEV
 * @author      Thomas Zukal
 * @copyright   Copyright (c) 2017-2018 Thomas Zukal
 * @link        https://github.com/BluesatKV/jquery-tabledit
 *
 * @language    EN - Thomas Zukal (https://github.com/BluesatKV)
 *              DE -
 *              FR - Twimmcook (https://github.com/Twimmcook)
 *              CZ - Thomas Zukal (https://github.com/BluesatKV)
 *
 * REQUIRED USER OPTIONS
 * --------------------
 *
 *  columns: {
 *
 *    // Column used to identify table row.
 *    //
 *    //  column_index - index of column in table 0, 1, 2, 3 etc...
 *    //  input_name - name of column in your DB (MySQL)
 *    //
 *    // [column_index, input_name]
 *    identifier: [0, 'id'],
 *
 *    // Columns to transform in editable cells -> supported type "input", "hidden", "number", "date", "select", "textarea"
 *
 *    editable: [
 *
 *          // [[column_index, input_name, input_type_text]
 *          [1, 'col1', 'input'],
 *
 *          // [[column_index, input_name, input_type_hidden]
 *          [2, 'col2', 'hidden'],
 *
 *          // [[column_index, input_name, input_type_number]
 *          [3, 'col3', 'number'],
 *
 *          // [[column_index, input_name, input_type_date]
 *          [4, 'col4', 'date'],
 *
 *          // [[column_index, input_name, textarea_type, textarea_options] -> supported attributes "rows", "cols", "maxlength", "wrap"
 *          [5, 'col5', , 'textarea', '{"rows": "3", "cols": "10", "maxlength": "200", "wrap": "hard"}'],
 *
 *          [column_index, input_name, select_type, select_options]]
 *          [6, 'col6', 'select', '{"1": "Red", "2": "Green", "3": "Blue"}']
 *       ]
 *    }
 *
 */

if (typeof jQuery === 'undefined') {
  throw new Error('Tabledit requires jQuery library.');
}

// TABLE EDIT PLUGIN WITH METHOD
/**
 * $('#my_table').Tabledit(); -> calls the init method
 * $('#my_table').Tabledit({  -> calls the init method with user options
 *    lang : 'en'
 * });
 * $('#my_table').Tabledit('destroy'); -> calls the destroy method
 * $('#my_table').Tabledit('update'); -> calls the update method with init options
 * $('#my_table').Tabledit('update', {lang: 'de'}); -> calls the update method with new user options
 */
(function ($) {
  'use strict';

  //A variable to save the setting data under.
  var dataPrefix = '_TableditData';

  // Methods
  var methods = {
    init: function (options) {

      // jQuery wrapper for clicked element
      var $table = this;

      // Check if element is 'table'
      if ($table.prop("tagName") !== 'TABLE') {
        throw new Error('Tabledit only works when applied to a table.');
      }

      // Function - check if value isn't ...
      var notNull = function (value) {
        return value !== undefined || value !== null || value !== '';
      };

      // Check User Options isn't empty
      if (!notNull(options.columns)) {
        // Check if Required options exists
        console.log('Tabledit Jquery Plugin not initialize. Set required parameters.');
        return this;
      }

      if (notNull(options.lang) && options.lang in $table.Tabledit.langs) {
        // If Language exist in 'Tabledit.langs'
        options.lang = options.lang.toLowerCase();
      } else {
        // Set Language/localization
        options.lang = $table.Tabledit.defaults.lang;
      }

      // Overwrite default options with user provided ones and merge them into "settings" object for multiple instance
      var settings = $.extend({}, $table.Tabledit.defaults, options);

      // Save settings by using the 'data' function
      $(this).data(dataPrefix, $.extend({}, $table.Tabledit.defaults, options || {}));

      var $lastEditedRow = 'undefined';
      var $lastDeletedRow = 'undefined';
      var $lastRestoredRow = 'undefined';

      // Set html for all buttons
      if (settings.editButton && settings.buttons.edit.html) {
        var editButtonHtml = settings.buttons.edit.html;
      } else {
        var editButtonHtml = $table.Tabledit.langs[settings.lang].btn_edit;
      }

      if (settings.deleteButton && settings.buttons.delete.html) {
        var deleteButtonHtml = settings.buttons.delete.html;
      } else {
        var deleteButtonHtml = $table.Tabledit.langs[settings.lang].btn_delete;
      }

      if (settings.confirmButton && settings.buttons.confirm.html) {
        var confirmButtonHtml = settings.buttons.confirm.html;
      } else {
        var confirmButtonHtml = $table.Tabledit.langs[settings.lang].btn_confirm;
      }

      if (settings.saveButton && settings.buttons.save.html) {
        var saveButtonHtml = settings.buttons.save.html;
      } else {
        var saveButtonHtml = $table.Tabledit.langs[settings.lang].btn_save;
      }

      if (settings.restoreButton && settings.buttons.restore.html) {
        var restoreButtonHtml = settings.buttons.restore.html;
      } else {
        var restoreButtonHtml = $table.Tabledit.langs[settings.lang].btn_restore;
      }

      // Output to console with data
      if (options.debug) console.log('Tabledit Init -> Element:', $table);
      if (options.debug) console.log('Tabledit Init -> dataPrefix:', dataPrefix);
      if (options.debug) console.log('Tabledit Init -> Settings: ', settings);
      if (options.debug) console.log('Tabledit Init: -----------------------------------');

      /**
       * Escape HTML
       *
       * @param {string} value
       */
      function escapeHTML(string) {
        var entityMap = {
          '&': '&amp;',
          '<': '&lt;',
          '>': '&gt;',
          '"': '', // &quot;
          "'": '', // &#39;
          '/': '&#x2F;',
          '`': '&#x60;',
          '=': '&#x3D;'
        };

        return String(string).replace(/[&<>"'`=\/]/g, function (s) {
          return entityMap[s];
        });
      }

      /**
       * AJAX Error Handling
       *
       * @param jqXHR
       * @param textStatus  {string}
       * @param errorThrown {string}
       */
      function handleAjaxError(jqXHR, textStatus, errorThrown) {
        var msg = '';
        var statusErrorMap = {
          '0': 'Not connect. Verify Network.',
          '400': 'Server understood the request, but request content was invalid [400].',
          '401': 'Unauthorized access [401].',
          '403': 'Forbidden resource can not be accessed [403].',
          '404': 'Requested page not found. [404]',
          '500': 'Internal Server Error [500].',
          '503': 'Service unavailable [503].'
        };

        if (jqXHR.status) {
          msg = statusErrorMap[jqXHR.status];
        } else if (textStatus == 'parsererror') {
          msg = "Ajax Error!! Parsing JSON Request failed. \n" + "Detail =>" + textStatus + ' : ' + errorThrown;
        } else if (textStatus === 'timeout') {
          msg = 'Time out error.';
        } else if (textStatus === 'abort') {
          msg = 'Ajax request aborted.';
        } else {
          msg = 'Uncaught Error.\n' + jqXHR.responseText;
        }

        return msg;
      }

      /**
       * Send AJAX request to server.
       *
       * @param {string} action
       */
      function ajax(action) {
        var jqXHR;
        var result;
        var serialize = $table.find('.tabledit-input').serialize();

        if (!serialize) {
          return false;
        }

        serialize += '&action=' + action;

        result = settings.onAjax(action, serialize);

        // In onAjax() it is possible to modify the document sent in ajax request, e.g. adding additional information required by server, or do formatting / restructing of document to be sent.
        if (result === false) {
          return false;
        } else {
          serialize = result;
        }

        settings.method = settings[action + 'method'];

        // AJAX SETUP CSRF TOKEN
        function getCookie(name) {
          var cookieValue = null;
          if (document.cookie && document.cookie != '') {
            var cookies = document.cookie.split(';');
            for (var i = 0; i < cookies.length; i++) {
              var cookie = jQuery.trim(cookies[i]);
              // Does this cookie string begin with the name we want?
              if (cookie.substring(0, name.length + 1) == (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
              }
            }
          }
          return cookieValue;
        }

        function csrfSafeMethod(method) {
          // these HTTP methods do not require CSRF protection
          return (/^(GET|HEAD|OPTIONS|TRACE)$/.test(method));
        }

        $.ajaxSetup({
          beforeSend: function (xhr, s) {
            // Setting the token on the AJAX request
            if (!csrfSafeMethod(s.type) && !this.crossDomain) {
              xhr.setRequestHeader("X-CSRFToken", getCookie('csrftoken'));
            }
          }
        });

        // AJAX
        jqXHR = $.ajax({
          url: settings.url,
          type: settings.method,
          data: serialize,
          dataType: 'json'
        });

        // DONE callback-manipulation function - success
        jqXHR.done(function (data, textStatus, jqXHR) {
          // When AJAX call is successfuly

          // `data` contains parsed JSON

          if (textStatus == 'success') {
            if (action === settings.buttons.edit.action) {
              $lastEditedRow.removeClass(settings.dangerClass).addClass(settings.successClass);
              setTimeout(function () {
                //$lastEditedRow.removeClass(settings.successClass);
                $table.find('tr.' + settings.successClass).removeClass(settings.successClass);
              }, 1500);
            }

            // Initiate save successful custom callback
            settings.onSuccess(data, textStatus, jqXHR);
          } else {
            // Initiate save failed custom callback
            settings.onFail(textStatus);
          }

        });

        // FAIL callback-manipulation function - error
        jqXHR.fail(function (jqXHR, textStatus, errorThrown) {
          // When AJAX call has failed

          if (action === settings.buttons.delete.action) {
            $lastDeletedRow.removeClass(settings.mutedClass).addClass(settings.dangerClass);
            $lastDeletedRow.find('.tabledit-toolbar button').attr('disabled', false);
            $lastDeletedRow.find('.tabledit-toolbar .tabledit-restore-button').hide();
          } else if (action === settings.buttons.edit.action) {
            $lastEditedRow.addClass(settings.dangerClass);
          }

          // Initiate save failed custom callback
          settings.onFail(jqXHR, exception);

          // Output to console with data
          if (options.debug) console.log(handleAjaxError(jqXHR, textStatus, errorThrown));

        });

        // ALWAYS callback-manipulation function - complete
        jqXHR.always(function () {
          // When AJAX call is complete, will fire upon success or when error is thrown

          settings.onAlways();

        });

        return jqXHR;
      }

      /**
       * Draw Tabledit structure (identifier column, editable columns, toolbar column).
       *
       * @type {object}
       */
      var Draw = {
        columns: {
          identifier: function () {
            // Hide identifier column.
            if (settings.hideIdentifier) {
              $table.find('th:nth-child(' + parseInt(settings.columns.identifier[0]) + 1 + '), tbody td:nth-child(' + parseInt(settings.columns.identifier[0]) + 1 + ')').hide();
            }

            // var $td = $table.find('tbody td:nth-child(' + (parseInt(settings.columns.identifier[0]) + 1) + ')');
            var $td = $table.find('tbody tr:not(".' + settings.noEditClass + '") td:not(".' + settings.noEditClass + '")').filter(':nth-child(' + (parseInt(settings.columns.identifier[0]) + 1) + ')');

            $td.each(function () {
              // Get text of this cell.
              var text = $.trim($(this).text().replace(/^\s+|\s+$/g, ''));
              var text = settings.escapehtml ? escapeHTML(text) : text;

              // Create hidden input with row identifier.
              var span = '<span class="tabledit-span tabledit-identifier">' + text + '</span>';
              var input = '<input class="tabledit-input tabledit-identifier" type="hidden" name="' + settings.columns.identifier[1] + '" value="' + text + '" disabled>';

              // Add elements to table cell.
              $(this).html(span + input);

              // Add attribute "id" to table row.
              $(this).parent('tr').attr(settings.rowIdentifier, $.trim($(this).text()));
            });
          },
          editable: function () {
            for (var i = 0; i < settings.columns.editable.length; i++) {
              var $td = $table.find('tbody tr:not(".' + settings.noEditClass + '") td:not(".' + settings.noEditClass + '")').filter(':nth-child(' + (parseInt(settings.columns.editable[i][0]) + 1) + ')');

              $td.each(function () {
                // Get text of this cell
                // RegEx (Trim Leading and Trailing) -> Before: "   a b    c d e " / After: "a b    c d e"
                var text = $.trim($(this).text().replace(/(^\s+|\s+$)/g, ''));
                var text = settings.escapehtml ? escapeHTML(text) : text;

                // Add pointer as cursor.
                if (!settings.editButton) {
                  $(this).css('cursor', 'pointer');
                }

                // Create span element.
                var span = '<span class="tabledit-span">' + text + '</span>';
                var input;

                // Section for settings of valid types, values, attributes and other ...
                // -----------------------------------
                // List of valid types for columnType
                var supportedTypes = ["input", "hidden", "number", "date", "select", "textarea"];
                // List of valid attributes for columnType 'textarea'
                var supportedAttrTextarea = ["rows", "cols", "maxlength", "wrap"];
                // -----------------------------------

                // Get type from colums user definition
                var columnType = settings.columns.editable[i][2];

                // Set default element if not of supported type
                if ($.inArray(columnType, supportedTypes) == -1) {
                  columnType = 'input';
                }

                // Create element by type
                switch (columnType) {
                  case 'input':

                    // Create text input element.
                    input = '<input class="tabledit-input ' + settings.inputClass + '" type="text" name="' + settings.columns.editable[i][1] + '" value="' + text + '" style="display: none;" disabled>';

                    break;
                  case 'hidden':

                    // Create text input element.
                    input = '<input class="tabledit-input ' + settings.inputClass + '" type="hidden" name="' + settings.columns.editable[i][1] + '" value="' + text + '" style="display: none;" disabled>';

                    break;
                  case 'number':

                    // Create text input element.
                    input = '<input class="tabledit-input ' + settings.inputClass + '" type="number" name="' + settings.columns.editable[i][1] + '" value="' + text + '" style="display: none;" disabled>';

                    break;
                  case 'date':
                    // NOTE: [type="date"] is not supported in Firefox, or Internet Explorer 11 and earlier versions

                    // Create text input element.
                    input = '<input class="tabledit-input ' + settings.inputClass + '" type="date" name="' + settings.columns.editable[i][1] + '" value="' + text + '" style="display: none;" disabled>';

                    break;
                  case 'select':

                    // Check if exists the third parameter of editable array.
                    if (typeof settings.columns.editable[i][3] !== 'undefined') {
                      // Create select element.
                      input = '<select class="tabledit-input ' + settings.inputClass + '" name="' + settings.columns.editable[i][1] + '" style="display: none;" disabled>';

                      // Create options for select element.
                      $.each($.parseJSON(settings.columns.editable[i][3]), function (index, value) {
                        value = $.trim(value);

                        if (text === value) {
                          input += '<option value="' + index + '" selected>' + value + '</option>';
                        } else {
                          input += '<option value="' + index + '">' + value + '</option>';
                        }
                      });

                      // Create last piece of select element.
                      input += '</select>';
                    }

                    break;
                  case 'textarea':

                    var counttext;

                    // Create textarea element.
                    input = '<textarea ';

                    // Check if exists the third parameter of editable array.
                    if (typeof settings.columns.editable[i][3] !== 'undefined') {

                      $.each($.parseJSON(settings.columns.editable[i][3]), function (index, value) {

                        // Ignore attribute if not of supported type
                        input += ($.inArray(index, supportedAttrTextarea) != -1) ? index + '="' + value + '" ' : '';

                        // Check if maxlength attribute exists and set text to character count
                        if (index == 'maxlength' && value.length > 0) {
                          counttext = ($table.Tabledit.langs[settings.lang].txt_allowchar).replace('%s', value) + ' | <span class="countno_"></span> ' + $table.Tabledit.langs[settings.lang].txt_remain;
                        } else {
                          counttext = $table.Tabledit.langs[settings.lang].txt_nolimit;
                        }

                      });

                    } else {
                      counttext = $table.Tabledit.langs[settings.lang].txt_nolimit;
                    }

                    input += ' class="tabledit-input ' + settings.inputClass + '" name="' + settings.columns.editable[i][1] + '" style="display: none;" disabled>' + text + '</textarea><span class="count_" style="display: none;">' + counttext + '</span>';

                    break;

                }

                // Add elements and class "view" to table cell.
                $(this).html(span + input);
                $(this).addClass('tabledit-view-mode');
              });
            }
          },
          toolbar: function () {
            if (settings.editButton || settings.deleteButton) {
              var editButton = '';
              var deleteButton = '';
              var saveButton = '';
              var restoreButton = '';
              var confirmButton = '';

              // Add toolbar column header if not exists.
              if ($table.find('th.tabledit-toolbar-column').length === 0) {
                $table.find('tr:first').append('<th class="tabledit-toolbar-column ' + settings.toolbarHeaderClass + '">' + $table.Tabledit.langs[settings.lang].txt_action + '</th>');
              }

              // Create edit button.
              if (settings.editButton) {
                editButton = '<button type="button" class="tabledit-edit-button ' + settings.buttons.edit.class + '" style="float: none;">' + editButtonHtml + '</button>';
              }

              // Create delete button.
              if (settings.deleteButton) {
                deleteButton = '<button type="button" class="tabledit-delete-button ' + settings.buttons.delete.class + '" style="float: none; ">' + deleteButtonHtml + '</button>';
                confirmButton = '<button type="button" class="tabledit-confirm-button ' + settings.buttons.confirm.class + '" style="display: none; float: none; margin-left: 10px;">' + confirmButtonHtml + '</button>';
              }

              // Create save button.
              if (settings.editButton && settings.saveButton) {
                saveButton = '<button type="button" class="tabledit-save-button ' + settings.buttons.save.class + '" style="display: none; float: none; margin-left: 10px;">' + saveButtonHtml + '</button>';
              }

              // Create restore button.
              if (settings.deleteButton && settings.restoreButton) {
                restoreButton = '<button type="button" class="tabledit-restore-button ' + settings.buttons.restore.class + '" style="display: none; float: none; margin-left: 10px;">' + restoreButtonHtml + '</button>';
              }

              var toolbar = '<div class="tabledit-toolbar ' + settings.toolbarClass + '" style="text-align: left;flex-wrap: nowrap;">\n\
                                           <div class="' + settings.groupClass + '" style="float: none;">' + editButton + deleteButton + '</div>\n\
                                           ' + saveButton + '\n\
                                           ' + confirmButton + '\n\
                                           ' + restoreButton + '\n\
                                       </div></div>';

              // Add toolbar column cells for normal cell
              $table.find('tbody > tr:not(".' + settings.noEditClass + '")').append('<td class="toolbar" style="white-space: nowrap; width: 1%;">' + toolbar + '</td>');
              // Add toolbar column with a ban on row editing
              $table.find('tbody > tr.' + settings.noEditClass).append('<td class="toolbar" style="white-space: nowrap; width: 1%;"></td>');
            }
          }
        }
      };

      /**
       * Change to view mode or edit mode with table td element as parameter.
       *
       * @type object
       */
      var Mode = {
        view: function (td) {
          // Get table row.
          var $tr = $(td).parent('tr');
          // Disable identifier.
          $(td).parent('tr').find('.tabledit-input.tabledit-identifier').prop('disabled', true);
          // Hide and disable input element.
          $(td).find('.tabledit-input').blur().hide().prop('disabled', true);
          // Hide count if exist for textarea
          $(td).find('.count_').hide();
          // Show span element.
          $(td).find('.tabledit-span').show();
          // Add "view" class and remove "edit" class in td element.
          $(td).addClass('tabledit-view-mode').removeClass('tabledit-edit-mode');
          // Update toolbar buttons.
          if (settings.editButton) {
            $tr.find('button.tabledit-save-button').hide();
            $tr.find('button.tabledit-edit-button').removeClass('active').blur();
          }
        },
        edit: function (td) {
          Delete.reset(td);
          // Get table row.
          var $tr = $(td).parent('tr');
          // Enable identifier.
          $tr.find('.tabledit-input.tabledit-identifier').prop('disabled', false);
          // Hide span element.
          $(td).find('.tabledit-span').hide();
          // Get input element.
          var $input = $(td).find('.tabledit-input');
          // Enable and show input element.
          $input.prop('disabled', false).show();
          // Set style for textarea
          $(td).find('textarea').css({"resize": "none"});
          // Show count if exist for textarea and set style
          $(td).find('.count_').css({"color": "#CCC", "display": "block", "float": "right"}).show();
          $(td).find('.countno_').html('...');
          // Focus on input element.
          if (settings.autoFocus) {
            $input.focus();
          }
          // Add "edit" class and remove "view" class in td element.
          $(td).addClass('tabledit-edit-mode').removeClass('tabledit-view-mode');
          // Update toolbar buttons.
          if (settings.editButton) {
            $tr.find('button.tabledit-edit-button').addClass('active');
            $tr.find('button.tabledit-save-button').show();
          }
        }
      };

      /**
       * Available actions for edit function, with table td element as parameter or set of td elements.
       *
       * @type object
       */
      var Edit = {
        reset: function (td) {
          $(td).each(function () {
            // Get input element.
            var $input = $(this).find('.tabledit-input');
            // Get span text.
            var text = $.trim($(this).find('.tabledit-span').text());
            // Set input/select value with span text.
            if ($input.is('select')) {
              $input.find('option').filter(function () {
                return $.trim($(this).text()) === text;
              }).attr('selected', true);
            } else {
              $input.val(text);
            }
            // Change to view mode.
            Mode.view(this);
          });
        },
        submit: function (td) {

          // Send AJAX request to server.
          var ajaxResult = ajax(settings.buttons.edit.action);

          if (ajaxResult === false) {
            return;
          }

          $(td).each(function () {
            // Get input element.
            var $input = $(this).find('.tabledit-input');
            // Set span text with input/select new value.
            if ($input.is('select')) {
              $(this).find('.tabledit-span').text($.trim($input.find('option:selected').text()));
            } else {
              $(this).find('.tabledit-span').text($input.val());
            }
            // Change to view mode.
            Mode.view(this);
          });

          // Set last edited column and row.
          $lastEditedRow = $(td).parent('tr');
        }
      };

      /**
       * Available actions for delete function, with button as parameter.
       *
       * @type object
       */
      var Delete = {
        reset: function (td) {
          // Reset delete button to initial status.
          $table.find('.tabledit-confirm-button').hide();
          // Remove "active" class in delete button.
          $table.find('.tabledit-delete-button').removeClass('active').blur();
        },
        submit: function (td) {
          Delete.reset(td);
          // Enable identifier hidden input.
          $(td).parent('tr').find('input.tabledit-identifier').attr('disabled', false);
          // Send AJAX request to server.
          var ajaxResult = ajax(settings.buttons.delete.action);
          // Disable identifier hidden input.
          $(td).closest('tr').find('input.tabledit-identifier').attr('disabled', true);

          if (ajaxResult === false) {
            return;
          }

          // Add class "deleted" to row.
          $(td).parent('tr').addClass('tabledit-deleted-row');
          // Hide table row.
          $(td).parent('tr').addClass(settings.mutedClass).find('.tabledit-toolbar button:not(.tabledit-restore-button)').attr('disabled', true);
          // Show restore button.
          $(td).find('.tabledit-restore-button').show();
          // Set last deleted row.
          $lastDeletedRow = $(td).parent('tr');
        },
        confirm: function (td) {
          // Reset all cells in edit mode.
          $table.find('td.tabledit-edit-mode').each(function () {
            Edit.reset(this);
          });
          // Add "active" class in delete button.
          $(td).find('.tabledit-delete-button').addClass('active');
          // Show confirm button.
          $(td).find('.tabledit-confirm-button').show();
        },
        restore: function (td) {
          // Enable identifier hidden input.
          $(td).parent('tr').find('input.tabledit-identifier').attr('disabled', false);
          // Send AJAX request to server.
          var ajaxResult = ajax(settings.buttons.restore.action);
          // Disable identifier hidden input.
          $(td).closest('tr').find('input.tabledit-identifier').attr('disabled', true);

          if (ajaxResult === false) {
            return;
          }

          // Remove class "deleted" to row.
          $(td).parent('tr').removeClass('tabledit-deleted-row');
          // Hide table row.
          $(td).parent('tr').removeClass(settings.mutedClass).find('.tabledit-toolbar button').attr('disabled', false);
          // Hide restore button.
          $(td).find('.tabledit-restore-button').hide();
          // Set last restored row.
          $lastRestoredRow = $(td).parent('tr');
        }
      };

      // Draw columns
      Draw.columns.identifier();
      Draw.columns.editable();
      Draw.columns.toolbar();

      settings.onDraw();

      if (settings.deleteButton) {
        /**
         * Delete one row.
         *
         * @param {object} event
         */
        $table.on('click', 'button.tabledit-delete-button', function (event) {
          if (event.handled !== true) {

            // Stop, the default action of the event will not be triggered
            event.preventDefault();

            // Get current state before reset to view mode.
            var activated = $(this).hasClass('active');

            var $td = $(this).closest('td');

            Delete.reset($td);

            if (!activated) {
              Delete.confirm($td);
            }

            event.handled = true;
          }
        });

        /**
         * Delete one row (confirm).
         *
         * @param {object} event
         */
        $table.on('click', 'button.tabledit-confirm-button', function (event) {
          if (event.handled !== true) {

            // Stop, the default action of the event will not be triggered
            event.preventDefault();

            var $td = $(this).closest('td');

            Delete.submit($td);

            event.handled = true;
          }
        });
      }

      if (settings.restoreButton) {
        /**
         * Restore one row.
         *
         * @param {object} event
         */
        $table.on('click', 'button.tabledit-restore-button', function (event) {
          if (event.handled !== true) {

            // Stop, the default action of the event will not be triggered
            event.preventDefault();

            Delete.restore($(this).closest('td'));

            event.handled = true;
          }
        });
      }

      if (settings.editButton) {
        /**
         * Activate edit mode on all columns.
         *
         * @param {object} event
         */
        $table.on('click', 'button.tabledit-edit-button', function (event) {
          if (event.handled !== true) {

            // Stop, the default action of the event will not be triggered
            event.preventDefault();

            var $button = $(this);

            // Get current state before reset to view mode.
            var activated = $button.hasClass('active');

            // Change to view mode columns that are in edit mode.
            Edit.reset($table.find('td.tabledit-edit-mode'));

            if (!activated) {
              // Change to edit mode for all columns in reverse way.
              $($button.closest('tr').find('td.tabledit-view-mode').get().reverse()).each(function () {
                Mode.edit(this);
              });
            }

            event.handled = true;
          }
        });

        /**
         * Save edited row.
         *
         * @param {object} event
         */
        $table.on('click', 'button.tabledit-save-button', function (event) {
          if (event.handled !== true) {

            // Stop, the default action of the event will not be triggered
            event.preventDefault();

            // Submit and update all columns.
            Edit.submit($(this).closest('tr').find('td.tabledit-edit-mode'));

            event.handled = true;
          }
        });
      } else {
        /**
         * Change to edit mode on table td element.
         *
         * @param {object} event
         */
        $table.on(settings.eventType, 'tr:not(.tabledit-deleted-row) td.tabledit-view-mode', function (event) {
          if (event.handled !== true) {

            // Stop, the default action of the event will not be triggered
            event.preventDefault();

            // Reset all td's in edit mode.
            Edit.reset($table.find('td.tabledit-edit-mode'));

            // Change to edit mode.
            Mode.edit(this);

            event.handled = true;
          }
        });

        /**
         * Change event when input is a select element.
         */
        $table.on('change', 'select.tabledit-input:visible', function (event) {
          if (event.handled !== true) {
            // Submit and update the column.
            Edit.submit($(this).parent('td'));

            event.handled = true;
          }
        });

        /**
         * Click event on document element.
         *
         * @param {object} event
         */
        $(document).on('click', function (event) {
          var $editMode = $table.find('.tabledit-edit-mode');
          // Reset visible edit mode column.
          if (!$editMode.is(event.target) && $editMode.has(event.target).length === 0) {
            Edit.reset($table.find('.tabledit-input:visible').parent('td'));
          }
        });
      }

      /**
       * Keypress event on table element.
       *
       * @param {object} event
       */
      $table.on('keypress', function (event) {

        // Get input element with focus or confirmation button.
        var $input = $table.find('.tabledit-input:visible');
        var $button = $table.find('.tabledit-confirm-button');

        if ($input.length > 0) {
          var $td = $input.parents('td');
        } else if ($button.length > 0) {
          var $td = $button.parents('td');
        } else {
          return;
        }

        // Key?
        switch (event.keyCode) {
          case 9:  // Tab.

            if (!settings.editButton) {
              Edit.submit($td);
              Mode.edit($td.closest('td').next());
            }

            break;
          case 13: // Enter.

            // Stop, the default action of the event will not be triggered
            event.preventDefault();

            Edit.submit($td);

            break;
          case 27: // Escape.

            Edit.reset($td);
            Delete.reset($td);

            break;
        }
      });

      /**
       * Keydown event on table textarea.
       *
       */
      $('textarea').on('change keyup keydown', function () {
        var length = $(this).val().length;
        // Get maxlength attribute
        var maxLength = $(this).attr('maxlength');
        // For some browsers, `attr` is undefined; for others, `attr` is false. Check for both.
        if (typeof maxLength !== typeof undefined && maxLength !== false) {
          if (maxLength.length > 0) {
            // Check the value and get the length of it, store it in a variable
            var length = maxLength - length;
            // Show result
            $(this).parent().find('.countno_').text(length);
          }
        }
      });

      return this;

    },
    destroy: function (options) {

      // jQuery wrapper for clicked element
      var $table = this;

      // Output to console with data
      if (options.debug) console.log('Tabledit Destroy -> Element:', $(this));

      // Remove toolbar column header
      $table.find('.tabledit-toolbar-column').remove();
      // Remove toolbar
      $table.find('.toolbar').remove();

      // Remove all '.tabledit-span' and all created element
      $table.find('td').each(function () {
        // Get input element.
        var $input = $(this).find('.tabledit-input');
        // Get span text.
        if ($input.length != 0) {
          var text = $.trim($(this).find('.tabledit-span').text());
        } else {
          var text = $.trim($(this).html());
        }
        // Put text to table cell
        $(this).html(text)

      });


      return;
    },
    update: function (options) {

      // jQuery wrapper for clicked element
      var $table = this;

      // Reload options by using the 'data' function
      var defaults = $(this).data(dataPrefix);

      // Log output if 'data' not exists
      if (!defaults) {
        console.log('Tabledit Update -> Data: EditTable must be initialized before setting options');
        return;
      }

      // Overwrite reload options with user provided ones and merge them into "options" - recursively
      var options = $.extend(true, defaults, options);


      // Output to console with data
      if (options.debug) console.log('Tabledit Update -> Element:', $(this));
      if (options.debug) console.log('Tabledit Update -> Settings: ', options);

      // Get only debug options in all 'options' and create object from json
      // This is only one options for destroy method calling from 'update' method
      var debugoption = $.parseJSON(JSON.stringify(options, ['debug']));

      // Call 'init' method function with options
      methods.destroy.apply(this, [debugoption]);

      // Call 'init' method function with options
      methods.init.apply(this, [options]);
    }
  };

  // CALL PLUGIN METHOD
  $.fn.Tabledit = function (method) {
    if (methods[method]) {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'object' || !method) {
      // Default to "init"
      return methods.init.apply(this, arguments);
    } else {
      $.error('Method ' + method + ' does not exist on jQuery.Tabledit');
    }
  };

  // SET DEFAULT OPTIONS
  $.fn.Tabledit.defaults = {
    // Link to server script
    url: window.location.href,
    // Server request method for action 'edit' and 'delete'
    editmethod: 'post',
    deletemethod: 'post',
    // Class for toolbar header column
    toolbarHeaderClass: '',
    // Class for buttons toolbar
    toolbarClass: 'btn-toolbar',
    // Class for buttons group
    groupClass: 'btn-group btn-group-sm',
    // Class for form inputs
    inputClass: 'form-control input-sm',
    // Class for row when ajax request fails
    dangerClass: 'danger',
    // Class for row when save changes
    successClass: 'success',
    // Class for row when is deleted
    mutedClass: 'text-muted',
    // Class for prohibiting cell editing
    noEditClass: 'noedit',
    // Trigger to change for edit mode
    eventType: 'click',
    // Change the name of attribute in td element for the row identifier
    rowIdentifier: 'id',
    // Hide the column that has the identifier
    hideIdentifier: false,
    // Activate focus on first input of a row when click in save button
    autoFocus: true,
    // Localization -(en, default) - LowerCase or UpperCase
    lang: 'en',
    // Debug mode
    debug: false,
    // Escape Html - convert hmtl character
    escapehtml: true,
    // Activate edit button instead of spreadsheet style
    editButton: true,
    // Activate delete button
    deleteButton: true,
    // Activate save button when click on edit button
    saveButton: true,
    // Activate restore button to undo delete action
    restoreButton: true,
    // Customize buttons created in the table
    buttons: {
      edit: {
        class: 'btn btn-sm btn-default',
        html: '<span class="glyphicon glyphicon-pencil"></span>',
        action: 'edit'
      },
      delete: {
        class: 'btn btn-sm btn-default',
        html: '<span class="glyphicon glyphicon-trash"></span>',
        action: 'delete'
      },
      save: {
        class: 'btn btn-sm btn-success',
        html: ''
      },
      restore: {
        class: 'btn btn-sm btn-warning',
        html: '',
        action: 'restore'
      },
      confirm: {
        class: 'btn btn-sm btn-danger',
        html: 'Confirm'
      }
    },
    /**
     * REQUIRED - Set up in user options
     * Identifier column and editable columns
     * More info in Documentation (https://markcell.github.io/jquery-tabledit/#documentation)
     * columns: '',
     */
    // Executed after draw the structure
    onDraw: function () {
      return;
    },
    // Executed when the ajax request is completed
    onSuccess: function () {
      return;
    },
    // Executed when occurred an error on ajax request
    onFail: function () {
      return;
    },
    // Executed whenever there is an ajax request
    onAlways: function () {
      return;
    },
    // Executed before the ajax request
    onAjax: function () {
      return;
    }
  };

  // LANGUAGE/LOCALIZATION
  $.fn.Tabledit.langs = {
    en: {
      btn_edit: 'Edit',
      btn_delete: 'Delete',
      btn_confirm: 'Confirm',
      btn_save: 'Save',
      btn_restore: 'Restore',
      txt_action: 'Actions',
      txt_nolimit: 'Count of characters without limit',
      txt_allowchar: 'Allowed count of characters %s',
      txt_remain: 'characters remaining'
    },
    de: {
      btn_edit: 'Editieren',
      btn_delete: 'L&ouml;schen',
      btn_confirm: 'Best&auml;tigen',
      btn_save: 'Speichern',
      btn_restore: 'Inhalt',
      txt_action: 'Aktion',
      txt_nolimit: '',
      txt_allowchar: '',
      txt_remain: ''
    },
    fr: {
      btn_edit: 'Editer',
      btn_delete: 'Supprimer',
      btn_confirm: 'Confirmer',
      btn_save: 'Enregistrer',
      btn_restore: 'Restaurer',
      txt_action: 'Actions',
      txt_nolimit: 'Nombre de caractères sans limite',
      txt_allowchar: 'Nombre de caractères autorisés %s',
      txt_remain: 'caractères restants'
    },
    cz: {
      btn_edit: 'Editovat',
      btn_delete: 'Odstranit',
      btn_confirm: 'Potvrdit',
      btn_save: 'Uložit',
      btn_restore: 'Obnovit',
      txt_action: 'Akce',
      txt_nolimit: 'Počet znaků bez omezení',
      txt_allowchar: 'Povoleno celkem %s znaků',
      txt_remain: 'znak(ů) zbývá'
    }
  };

})(jQuery);
