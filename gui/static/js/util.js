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

    /* grab the fields */
    var elems = select_node.find('input,textarea,select,output').filter(':not(:hidden)').get();

    /* check the builtin form validation */
    for (var i = 0; i < elems.length; i++) {
      if (!elems[i].reportValidity()) {
        return false;
      }
    }

    /* if supplied, run the custom test function */
    if (typeof test === 'function') {
      var resp = test(elems);
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

    if (element.hasAttribute('on'+event)) {
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
   * @param {Boolean} error   whether its an error
   */
  window.showNotification = function(msg, error = false) {
    var top_bar = $('.top-bar');
    var msg_bar = $('.message-bar');
    var visible_modals = $('.modal').filter(':not(:hidden)');

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

    visible_modals.modal('hide');
    top_bar.show();
    top_bar.slideUp(10000, function() {
      top_bar.hide();
    });
  };

  /**
   * Update reload kamailio button to indicate if reload is required
   * @param {Boolean} required    whether a reload is required
   */
  window.reloadKamRequired = function(required = true) {
    var reload_button = $('#reloadkam');

    if (reload_button.length > 0) {
      if (required) {
        reload_button.removeClass('btn-primary');
        reload_button.addClass('btn-warning');
      }
      else {
        reload_button.removeClass('btn-warning');
        reload_button.addClass('btn-primary');
      }
    }
  };

})(window, document);
