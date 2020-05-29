/*
* THIS WORK IS PROVIDED "AS IS," AND COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE OR DOCUMENT WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.
* COPYRIGHT HOLDERS WILL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF ANY USE OF THE SOFTWARE OR DOCUMENT.
* The name and trademarks of copyright holders may NOT be used in advertising or publicity pertaining to the work without specific, written prior permission. Title to copyright in this work will at all times remain with copyright holders.
*
* Original Version [listbox-combobox.js]: https://www.w3.org/TR/wai-aria-practices/examples/combobox/aria1.1pattern/js/listbox-combobox.js
* Copyright © [2015] World Wide Web Consortium, (Massachusetts Institute of Technology, European Research Consortium for Informatics and Mathematics, Keio University, Beihang). All Rights Reserved. This work is distributed under the W3C® Software License [1] in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
* http://www.w3.org/Consortium/Legal/copyright-software
*
* Changes made by the dOpenSource Team
* Copyright © [2018] W3C®, dOpenSource
*/

;(function(window, document) {
  'use strict';

  /**
   * @namespace aria
   */
  var aria = aria || {};

  /**
   * Check aria widget for class
   * @param element
   * @param className
   * @returns {boolean}
   */
  aria.hasClass = function (element, className) {
    return (new RegExp('(\\s|^)' + className + '(\\s|$)')).test(element.className);
  };

  /**
   * Add class to aria widget
   * @param element
   * @param className
   */
  aria.addClass = function (element, className) {
    if (!aria.hasClass(element, className)) {
      element.className += ' ' + className;
    }
  };

  /**
   * Remove class from aria widget
   * @param element
   * @param className
   */
  aria.removeClass = function (element, className) {
    var classRegex = new RegExp('(\\s|^)' + className + '(\\s|$)');
    element.className = element.className.replace(classRegex, ' ').trim();
  };

  /**
   * Shortcuts for JS event key codes
   * @type {{UP: number, DOWN: number, ESC: number, ENTER: number, BACKSPACE: number, TAB: number}}
   */
  var KeyCodes = {
    'UP': 38,
    'DOWN': 40,
    'ESC': 27,
    'ENTER': 13,
    'BACKSPACE': 8,
    'TAB': 9
  };

  /**
   * @constructor
   *
   * @desc
   *    Combobox object representing the state and interactions for a combobox widget
   *
   * @param comboboxNode
   *    The DOM node pointing to the combobox
   * @param input
   *    The input node
   * @param listbox
   *    The listbox node to load results in
   * @param searchFn
   *    The search function. The function accepts a search string and returns an
   *    array of results.
   * @param shouldAutoSelect
   *    Whether to autoselect the current item when focus toggles
   * @param onShow
   *    Callback function on show
   * @param onHide
   *    Callback function on hide
   */
  aria.ListboxCombobox = function(comboboxNode, input, listbox, searchFn, shouldAutoSelect, onShow, onHide) {
    this.combobox = comboboxNode;
    this.input = input;
    this.listbox = listbox;
    this.searchFn = searchFn;
    this.shouldAutoSelect = shouldAutoSelect;
    this.onShow = onShow || function() {};
    this.onHide = onHide || function() {};
    this.activeIndex = -1;
    this.resultsCount = 0;
    this.shown = false;
    this.hasInlineAutocomplete = input.getAttribute('aria-autocomplete') === 'both';

    this.setupEvents();
  };

  aria.ListboxCombobox.prototype.setupEvents = function () {
    document.body.addEventListener('click', this.checkHide.bind(this));
    this.input.addEventListener('keyup', this.checkKey.bind(this));
    this.input.addEventListener('keydown', this.setActiveItem.bind(this));
    this.input.addEventListener('focus', this.checkShow.bind(this));
    this.input.addEventListener('blur', this.checkSelection.bind(this));
    this.listbox.addEventListener('click', this.clickItem.bind(this));
  };

  aria.ListboxCombobox.prototype.checkKey = function(evt) {
    var key = evt.which || evt.keyCode;

    switch (key) {
      case KeyCodes.UP:
      case KeyCodes.DOWN:
      case KeyCodes.ESC:
      case KeyCodes.ENTER:
        evt.preventDefault();
        return;
      default:
        this.updateResults(false);
    }

    if (this.hasInlineAutocomplete) {
      switch (key) {
        case KeyCodes.BACKSPACE:
          return;
        default:
          this.autocompleteItem();
      }
    }
  };

  aria.ListboxCombobox.prototype.updateResults = function(shouldShowAll) {
    var searchString = this.input.value;
    var results = this.searchFn(searchString);

    this.hideListbox();

    if (!shouldShowAll && !searchString) {
      results = [];
    }

    if (results.length) {
      for (var i = 0; i < results.length; i++) {
        var resultItem = document.createElement('li');
        resultItem.className = 'result';
        resultItem.setAttribute('role', 'option');
        resultItem.setAttribute('id', 'result-item-' + i);
        resultItem.innerText = results[i];
        if (this.shouldAutoSelect && i === 0) {
          resultItem.setAttribute('aria-selected', 'true');
          aria.addClass(resultItem, 'focused');
          this.activeIndex = 0;
        }
        this.listbox.appendChild(resultItem);
      }
      aria.removeClass(this.listbox, 'hidden');
      this.combobox.setAttribute('aria-expanded', 'true');
      this.resultsCount = results.length;
      this.shown = true;
      this.onShow();
    }
  };

  aria.ListboxCombobox.prototype.setActiveItem = function(evt) {
    var key = evt.which || evt.keyCode;
    var activeIndex = this.activeIndex;

    if (key === KeyCodes.ESC) {
      this.hideListbox();
      setTimeout((function() {
        // On Firefox, input does not get cleared here unless wrapped in a setTimeout
        this.input.value = '';
      }).bind(this), 1);
      return;
    }

    if (this.resultsCount < 1) {
      if (this.hasInlineAutocomplete && (key === KeyCodes.DOWN || key === KeyCodes.UP)) {
        this.updateResults(true);
      }
      else {
        return;
      }
    }

    var prevActive = this.getItemAt(activeIndex);
    var activeItem;

    switch (key) {
      case KeyCodes.UP:
        if (activeIndex <= 0) {
          activeIndex = this.resultsCount - 1;
        }
        else {
          activeIndex--;
        }
        break;
      case KeyCodes.DOWN:
        if (activeIndex === -1 || activeIndex >= this.resultsCount - 1) {
          activeIndex = 0;
        }
        else {
          activeIndex++;
        }
        break;
      case KeyCodes.ENTER:
        activeItem = this.getItemAt(activeIndex);
        this.selectItem(activeItem);
        return;
      case KeyCodes.TAB:
        this.checkSelection();
        this.hideListbox();
        return;
      default:
        return;
    }

    evt.preventDefault();

    activeItem = this.getItemAt(activeIndex);
    this.activeIndex = activeIndex;

    if (prevActive) {
      aria.removeClass(prevActive, 'focused');
      prevActive.setAttribute('aria-selected', 'false');
    }

    if (activeItem) {
      this.input.setAttribute(
        'aria-activedescendant',
        'result-item-' + activeIndex
      );
      aria.addClass(activeItem, 'focused');
      activeItem.setAttribute('aria-selected', 'true');
      if (this.hasInlineAutocomplete) {
        this.input.value = activeItem.innerText;
      }
    }
    else {
      this.input.setAttribute(
        'aria-activedescendant',
        ''
      );
    }
  };

  aria.ListboxCombobox.prototype.getItemAt = function(index) {
    return document.getElementById('result-item-' + index);
  };

  aria.ListboxCombobox.prototype.clickItem = function(evt) {
    if (evt.target && evt.target.nodeName === 'LI') {
      this.selectItem(evt.target);
    }
  };

  aria.ListboxCombobox.prototype.selectItem = function(item) {
    if (item) {
      this.input.value = item.innerText;
      this.hideListbox();
    }
  };

  aria.ListboxCombobox.prototype.checkShow = function(evt) {
    if (this.shown) {
      return;
    }
    this.updateResults(false);
  };

  aria.ListboxCombobox.prototype.checkHide = function(evt) {
    if (evt.target === this.input || this.combobox.contains(evt.target)) {
      var arrow = $(this.combobox).find('.did-combobox-arrow').get(0);
      if (evt.target === arrow || this.combobox.contains(arrow)) {
        if (this.combobox.shown) {
          this.hideListbox();
          this.combobox.shown = false;
        }
        else {
          this.updateResults(true);
          this.combobox.shown = true;
        }
      }
      return;
    }
    this.hideListbox();
  };

  aria.ListboxCombobox.prototype.hideListbox = function() {
    this.shown = false;
    this.activeIndex = -1;
    this.listbox.innerHTML = '';
    aria.addClass(this.listbox, 'hidden');
    this.combobox.setAttribute('aria-expanded', 'false');
    this.resultsCount = 0;
    this.input.setAttribute('aria-activedescendant', '');
    this.onHide();
  };

  aria.ListboxCombobox.prototype.checkSelection = function() {
    if (this.activeIndex < 0) {
      return;
    }
    var activeItem = this.getItemAt(this.activeIndex);
    this.selectItem(activeItem);
  };

  aria.ListboxCombobox.prototype.autocompleteItem = function() {
    var autocompletedItem = this.listbox.querySelector('.focused');
    var inputText = this.input.value;

    if (!autocompletedItem || !inputText) {
      return;
    }

    var autocomplete = autocompletedItem.innerText;
    if (inputText !== autocomplete) {
      this.input.value = autocomplete;
      this.input.setSelectionRange(inputText.length, autocomplete.length);
    }
  };

  /* export the namespace */
  window.aria = aria;

})(window, document);
