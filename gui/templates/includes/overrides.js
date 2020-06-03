;(function(window, document) {
  'use strict';

  // note that the ajax/fetch overrides do not effect XMLHttpRequest (a.k.a the XHR API)
  // external libs using the XHR functions will not be effected (unknown side effects)
  // in the future we may switch to overriding XMLHttpRequest instead of using ajax methods
  // ref: https://stackoverflow.com/questions/14527360/can-i-set-a-global-header-for-all-ajax-requests
  // ref: https://jsfiddle.net/cferdinandi/2mc2wnc7/
  // ref: https://jsfiddle.net/0bjfLey9/1
  // note that in the ajax implementation the global error handler runs AFTER any locally set error handlers
  // the inverse is true for the fetch implementation, the global error handler runs BEFORE user catch blocks

  // throw an error if required functions not defined
  if (typeof showNotification === "undefined") {
    throw new Error("showNotification() is required and is not defined");
  }
  if (typeof reloadKamRequired === "undefined") {
    throw new Error("reloadKamRequired() is required and is not defined");
  }

  // throw an error if required globals not defined
  if (typeof GUI_BASE_URL === "undefined") {
    throw new Error("GUI_BASE_URL is required and is not defined");
  }

  // global variables/constants for this script
  const NOCSRF_REQUEST_METHOD_REGEX = new RegExp(/^(GET|HEAD|OPTIONS|TRACE)$/, 'i');
  const OLD_FETCH = window.fetch;

  function requestErrorHandler(status, error_msg, error_type="http") {
    if (status < 400) {
      // not an error, likely a direct call to error handler
    }
    else if (status === 400) {
      // bad input show error in page
      console.error('requestErrorHandler(): ' + status.toString() + ' ' + error_msg)
      showNotification(error_msg, true);
    }
    else if (status === 401) {
      // unauthorized goto index for login
      console.error('requestErrorHandler(): ' + status.toString() + ' ' + error_msg)
      window.location.href = GUI_BASE_URL;
    }
    else if (status === 403) {
      // forbidden show error in page
      console.error('requestErrorHandler(): ' + status.toString() + ' ' + error_msg)
      showNotification(error_msg, true);
    }
    else if (status === 404) {
      // not found show error in page
      console.error('requestErrorHandler(): ' + status.toString() + ' ' + error_msg)
      showNotification(error_msg, true);
    }
    else {
      // unhandled error goto error page
      console.error('requestErrorHandler(): ' + status.toString() + ' ' + error_msg)
      window.location.href = GUI_BASE_URL + "error?type=" + error_type + "&code=" +
          status.toString() + "&msg=" + error_msg;
    }
  }

  // override ajax defaults
  $.ajaxSetup({
    // set anti-CSRF token
    beforeSend: function(xhr, settings) {
      if (!NOCSRF_REQUEST_METHOD_REGEX.test(settings.type) && !this.crossDomain) {
        xhr.setRequestHeader("X-CSRF-Token", "{{ csrf_token() }}");
      }
    }
  });
  $(document).ajaxError(function(event, xhr, settings, error_msg) {
    // handle HTTP errors, may redirect
    try {
      // try updating error message and type
      var data = JSON.parse(xhr.responseText);
      var error_type = data["error"];
      error_msg = data["msg"];
      requestErrorHandler(xhr.status, error_msg, error_type);
    }
    catch(error) {
      // non-JSON response or no error info in response, use defaults
      requestErrorHandler(xhr.status, xhr.statusText);
    }
  });
  $(document).ajaxComplete(function(event, xhr, settings) {
    try {
      // try updating kam reload button
      reloadKamRequired(JSON.parse(xhr.responseText)["kamreload"]);
    }
    catch(error) {
      // non-JSON response or no kamreload in response, continue
    }
  });

  // override fetch defaults
  window.fetch = function(resource, init) {
    // set anti-CSRF token
    // if init is undefined then method is GET and no anti-CSRF token needed
    if (init !== undefined && init.hasOwnProperty('method') && !NOCSRF_REQUEST_METHOD_REGEX.test(init.method)) {
      if (!(init.hasOwnProperty('mode') && init.mode.toLowerCase() === 'cors')) {
        init.headers = init.headers || {};
        init.headers["X-CSRF-Token"] = "{{ csrf_token() }}";
      }
    }
    return OLD_FETCH.call(this, resource, init).then(function(response) {
      // handle HTTP errors, may redirect
      try {
        var data = JSON.parse(response.text());
        // try updating kam reload button
        if (data.hasOwnProperty("kamreload")) {
          reloadKamRequired(data["kamreload"]);
        }
        // try updating error message and type
        var error_type = data["error"];
        var error_msg = data["msg"];
        requestErrorHandler(response.status, error_msg, error_type);
      }
      catch(error) {
        // non-JSON response or no error info in response, use defaults
        requestErrorHandler(response.status, response.statusText);
      }

      // pass on the response
      return response;
    }).catch(function(error) {
      requestErrorHandler(500, error.message);
      // if error handler doesn't redirect, reject the promise
      return Promise.reject(error);
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
