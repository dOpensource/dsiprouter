;(function(window, document) {
  'use strict';

  // note that the ajax/fetch overrides do not effect XMLHttpRequest (a.k.a the XHR API)
  // external libs using the XHR functions will not be effected (unknown side effects)
  // in the future we may switch to overriding XMLHttpRequest instead of using ajax methods
  // ref: https://stackoverflow.com/questions/14527360/can-i-set-a-global-header-for-all-ajax-requests
  // ref: https://jsfiddle.net/cferdinandi/2mc2wnc7/

  // throw an error if required functions not defined
  if (typeof showNotification === "undefined") {
    throw new Error("showNotification() is required and is not defined");
  }

  // throw an error if required globals not defined
  if (typeof GUI_BASE_URL === "undefined") {
    throw new Error("GUI_BASE_URL is required and is not defined");
  }

  // global variables/constants for this script
  const NOCSRF_REQUEST_METHOD_REGEX = new RegExp(/^(GET|HEAD|OPTIONS|TRACE)$/, 'i');
  const OLD_FETCH = window.fetch;

  function requestErrorHandler(status, error_msg) {
    if (status === 400) {
      // bad input show error in page
      console.error('HTTP Error: ' + status.toString() + ' ' + error_msg)
      showNotification(error_msg, true);
    }
    else if (status === 401) {
      // unauthorized goto index for login
      console.error('HTTP Error: ' + status.toString() + ' ' + error_msg)
      window.location.href = GUI_BASE_URL + "index";
    }
    else if (status === 403) {
      // forbidden show error in page
      console.error('HTTP Error: ' + status.toString() + ' ' + error_msg)
      showNotification(error_msg, true);
    }
    else if (status === 404) {
      // not found show error in page
      console.error('HTTP Error: ' + status.toString() + ' ' + error_msg)
      showNotification(error_msg, true);
    }
    else {
        // unhandled error goto error page
      console.error('HTTP Error: ' + status.toString() + ' ' + error_msg)
      window.location.href = GUI_BASE_URL + "error?type=http&code=" +
          status.toString() + "&msg=" + error_msg;
    }
  }

  // set anti-CSRF token for ajax requests
  // then set error handler for ajax requests
  $.ajaxSetup({
    beforeSend: function(xhr, settings) {
      if (!NOCSRF_REQUEST_METHOD_REGEX.test(settings.type) && !this.crossDomain) {
        xhr.setRequestHeader("X-CSRF-Token", "{{ csrf_token() }}");
      }
    }
  });
  $(document).ajaxError(function(event, xhr, settings, error_msg) {
    requestErrorHandler(xhr.status, xhr.statusText);
  });

  // set anti-CSRF token for fetch requests
  window.fetch = function(resource, init) {
    // if init is undefined then method is GET and no anti-CSRF token needed
    if (init !== undefined && init.hasOwnProperty('method') && !NOCSRF_REQUEST_METHOD_REGEX.test(init.method)) {
      if (!(init.hasOwnProperty('mode') && init.mode.toLowerCase() === 'cors')) {
        init.headers = init.headers || {};
        init.headers["X-CSRF-Token"] = "{{ csrf_token() }}";
      }
    }
    return OLD_FETCH.call(this, resource, init).then(function(response) {
      requestErrorHandler(response.status, response.statusText);
    }).catch(function(error) {
      requestErrorHandler(0, error.message);
    });
  };

  /*
   * IE/Safari polyfill for reportValidity() compatibility
   * credit: https://stackoverflow.com/questions/17550317/how-to-manually-show-a-html5-validation-message-from-a-javascript-function
   */
  if (!HTMLFormElement.prototype.reportValidity) {
    HTMLFormElement.prototype.reportValidity = function() {
      if (this.checkValidity()) return true;
      var btn = document.createElement('button');
      this.appendChild(btn);
      btn.click();
      this.removeChild(btn);
      return false;
    }
    window.HTMLFormElement.prototype.reportValidity = HTMLFormElement.prototype.reportValidity;
  }

})(window, document);
