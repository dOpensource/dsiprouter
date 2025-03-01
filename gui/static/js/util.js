;(function(window, document) {
  'use strict';

  /**
   * Get the value of a querystring
   * @param  {String} field     The field to get the value of
   * @param  {String} url       The URL to get the value from (optional)
   * @return {String}           The field value
   */
  window.getQueryString = function(field, url) {
    var href = url ? url : window.location.href;
    var reg = new RegExp('[?&]' + field + '=([^&#]*)', 'i');
    var string = reg.exec(href);
    return string ? string[1] : null;
  };

  /**
   * Disable / Re-enable a form submittable element<br>
   * Use this instead of the HTML5 disabled prop
   * @param {String|jQuery|Object} selector   The selector for element to toggle
   * @param {Boolean} disable                 Whether to disable or re-enable
   * @param {Boolean} child                   Whether to change cursor on child instead
   */
  window.toggleElemDisabled = function(selector, disable, child) {
    var select_elem = null;

    if (typeof selector === 'string' || selector instanceof String) {
      select_elem = $(selector);
    }
    else if (selector instanceof jQuery) {
      select_elem = selector;
    }
    else {
      console.err("toggleElemDisabled(): invalid selector argument");
      return;
    }

    /* by default change cursor on parent not child */
    child = child || false;

    if (disable) {
      if (!child) {
        select_elem.parent().css({'cursor': 'not-allowed'});
      }
      else {
        select_elem.css({'cursor': 'not-allowed'});
      }
      select_elem.css({
        'background-color': '#EEEEEE',
        'opacity': '0.7',
        'pointer-events': 'none'
      });
      select_elem.prop('readonly', true);
      select_elem.prop('tabindex', -1);
      select_elem.prop('disabled', true);
    }
    else {
      if (!child) {
        select_elem.parent().removeAttr('style');
      }
      select_elem.removeAttr('style');
      select_elem.prop('readonly', false);
      select_elem.prop('tabindex', 0);
      select_elem.prop('disabled', false);
    }
  };

  /**
   * Recursively search DOM tree until test is true<br>
   * Starts at and includes selected node, tests each descendant<br>
   * Note that test callback applies to jQuery objects throughout
   * @param {String|jQuery|Object} selector   The selector for start node
   * @param {Function} test                   Test to apply to each node
   * @return {jQuery|null}                    Returns found node or null
   */
  window.descendingSearch = function(selector, test) {
    var select_node = null;
    if (typeof selector === 'string' || selector instanceof String) {
      select_node = $(selector);
    }
    else if (selector instanceof jQuery) {
      select_node = selector;
    }
    else {
      return null;
    }

    var num_nodes = select_node.length || 0;
    if (num_nodes > 1) {
      for (var i = 0; i < num_nodes; i++) {
        if (test(select_node[i])) {
          return select_node[i];
        }
      }
    }
    else {
      if (test(select_node)) {
        return select_node;
      }
    }

    var node_list = select_node.children();
    if (node_list.length <= 0) {
      return null;
    }

    descendingSearch(node_list, test)
  };

  /**
   * Validate form fields in a selected node<br>
   * The optional test function is passed a an array of fields found<br>
   * Note that in this project our forms are usually the 1st child in a modal body<br>
   * If provided the test function should return an object of this structure:<br>
   * <pre>
   *    {
   *      result:     boolean                 - whether the test passed or failed
   *      err_node:   element|jQuery|Object   - the node that caused the failure
   *      err_msg:    String                  - the error message to display
   *    }
   * </pre>
   * @param {String|jQuery|Object} selector   Selector for a node with fields
   * @param {Function} test                   Custom validation test to run
   * @returns {Boolean}                       Whether the validation passed
   * @throws {Error}                          If selector is invalid
   */
  window.validateFields = function(selector, test) {
    var select_node = null;
    if (typeof selector === 'string' || selector instanceof String) {
      select_node = $(selector);
    }
    else if (selector instanceof jQuery) {
      select_node = selector;
    }
    else if (typeof selector === "object" || selector instanceof Object) {
      select_node = $(selector);
    }
    else {
      throw new Error("validateFields(): invalid selector argument");
    }

    /* grab the fields as a jquery object */
    var field_elem_list = select_node.find('input,textarea,select,output').filter(':not(:hidden)').get();

    /* check the builtin form validation */
    for (var i = 0; i < field_elem_list.length; i++) {
      if (!field_elem_list[i].reportValidity()) {
        return false;
      }
    }

    /* if supplied, run the custom test function */
    if (typeof test === 'function') {
      // convert the array of DOM elements into a Map of "name" => jQuery(elem) key pairs
      var fields = new Map(field_elem_list.map(function(elem) {
        return [elem.getAttribute('name'), $(elem)];
      }));

      var resp = test(fields);
      if (resp.result === false) {
        var err_elem = null;
        if (resp.err_node instanceof jQuery) {
          err_elem = resp.err_node.get(0);
        }
        else {
          err_elem = resp.err_node;
        }

        err_elem.setCustomValidity(resp.err_msg);
        err_elem.reportValidity();
        setTimeout(function() {
          err_elem.setCustomValidity('');
        }, 2500);
        return false;
      }
    }

    return true;
  };

  /**
   * Checks if selected element has a particular event listener<br>
   * Works for on<event> DOM events, and dynamic events added using jquery<br>
   * Events added dynamically using addEventListener will not be found
   * @param {String|jQuery|Object} selector   Selector for a node with fields
   * @param {String} event                    Event listener type to check for
   * @returns {Boolean}
   * @throws {Error}                          If selector is invalid
   */
  function hasEventListener(selector, event) {
    var element = undefined;
    if (typeof selector === 'string' || selector instanceof String) {
      element = $(selector).get(0);
    }
    else if (selector instanceof jQuery) {
      element = selector.get(0);
    }
    else if (typeof selector === "object" || selector instanceof Object) {
      element = $(selector).get(0);
    }
    if (element === undefined) {
      throw new Error("validateFields(): invalid selector argument");
    }

    if (element.hasAttribute('on' + event)) {
      return true;
    }
    else if ($._data(element, "events").hasOwnProperty(event)) {
      return true;
    }
    return false;
  }

  /**
   * Show notification in top notification bar
   * @param {String} msg      message to display
   * @param {Boolean} error   whether the notification is an error
   */
  window.showNotification = function(msg, error = false, duration = 10000) {
    var top_bar = $('.top-bar');
    var msg_bar = $('.message-bar');
    var visible_modals = $('.modal').filter(':not(:hidden)');

    // hide modals if shown
    visible_modals.modal('hide');

    // stop the animation if already running
    top_bar.stop(true, true);

    // change the notification accordingly
    if (error === true) {
      msg_bar.removeClass("alert-success");
      msg_bar.addClass("alert alert-danger");
      msg_bar.html("<strong>Failed!</strong> " + msg);
    }
    else {
      msg_bar.removeClass("alert-danger");
      msg_bar.addClass("alert alert-success");
      msg_bar.html("<strong>Success!</strong> " + msg);
    }

    // start the animation showing the notification
    top_bar.show();
    top_bar.slideUp(duration, function() {
      top_bar.hide();
    });
  };

  /**
   * Update reload kamailio button to indicate if reload is required
   * @param {Boolean} required    whether a reload is required
   */
  window.reloadKamRequired = function(required = true) {
    var reload_btn = $('#reload');
    var split_btn = $('#reload-split');
    var kamailio_btn = $('#reload_kam');

    if (required) {
      reload_btn.removeClass('btn-primary');
      split_btn.removeClass('btn-primary');
      kamailio_btn.removeClass('btn-secondary');
      reload_btn.addClass('btn-warning');
      split_btn.addClass('btn-warning');
      kamailio_btn.addClass('btn-warning');
    }
    else {
      reload_btn.removeClass('btn-warning');
      split_btn.removeClass('btn-warning');
      kamailio_btn.removeClass('btn-warning');
      reload_btn.addClass('btn-primary');
      split_btn.addClass('btn-primary');
      kamailio_btn.addClass('btn-secondary');
    }
  };

  /**
   * Update reload dsiprouter button to indicate if reload is required
   * @param {Boolean} required    whether a reload is required
   */
  window.reloadDsipRequired = function(required = true) {
    var reload_btn = $('#reload');
    var split_btn = $('#reload-split');
    var dsiprouter_btn = $('#reload_dsip');

    if (required) {
      reload_btn.removeClass('btn-primary');
      split_btn.removeClass('btn-primary');
      dsiprouter_btn.removeClass('btn-secondary');
      reload_btn.addClass('btn-warning');
      split_btn.addClass('btn-warning');
      dsiprouter_btn.addClass('btn-warning');
    }
    else {
      reload_btn.removeClass('btn-warning');
      split_btn.removeClass('btn-warning');
      dsiprouter_btn.removeClass('btn-warning');
      reload_btn.addClass('btn-primary');
      split_btn.addClass('btn-primary');
      dsiprouter_btn.addClass('btn-secondary');
    }
  };

  /**
   * Run a function periodically until successful or timed out
   * @param {Function}  run_fn      Function to run (must return true or false in a Promise)
   * @param {Number}    timeout     Timeout (ms) until failure
   * @param {Number}    interval    Period (ms) between attempting run_fn again
   * @param {Function}  success_fn  Function to run on successful completion
   * @param {Function}  timeout_fn  Function to run on timeout failure
   */
  window.runUntilTimeout = function(
    run_fn, timeout, interval = 1000,
    success_fn = null, timeout_fn = null
  ) {
    var timeout_timer = setTimeout(function() {
      // ran unsuccessfully until timeout
      clearInterval(interval_timer);
      if (timeout_fn !== null) {
        timeout_fn();
      }
    }, timeout);

    var interval_timer = setInterval(function() {
      run_fn().then((result) => {
        if (result === true) {
          // ran successfully without timeout
          clearInterval(interval_timer);
          clearTimeout(timeout_timer);
          if (success_fn !== null) {
            success_fn();
          }
        }
      });
    }, interval);
  }

  /**
   * Queued delay of a callback
   * @param fn  The callback function
   * @param ms  The timeout in milliseconds
   * @returns {(function(...[*]): void)|*}
   */
  window.delayedCallback = function(fn, ms) {
    let timer = 0
    return function(...args) {
      clearTimeout(timer)
      timer = setTimeout(fn.bind(this, ...args), ms || 0)
    }
  };

})(window, document);
