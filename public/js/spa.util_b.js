// Generated by CoffeeScript 1.6.3
/*
spa.util_b.coffee
Avatar feature module
*/


(function() {
  var configMap, decodeHtml, encodeHtml, getEmSize;

  configMap = {
    regex_encode_html: /[&"'><]/g,
    regex_encode_noamp: /["'><]/g,
    html_encode_map: {
      '&': '&#38;',
      '"': '&#34;',
      "'": '&#39;',
      '>': '&#62;',
      '<': '&#60;'
    }
  };

  configMap.encode_noamp_map = $.extend({}, configMap.html_encode_map);

  delete configMap.encode_noamp_map['&'];

  decodeHtml = function(str) {
    return $('<div/>').html(str || '').text();
  };

  encodeHtml = function(input_arg_str, exclude_amp) {
    var input_str, lookup_map, map_match, regex;
    input_str = String(input_arg_str);
    if (exclude_amp) {
      lookup_map = configMap.encode_noamp_map;
      regex = configMap.regex_encode_noamp;
    } else {
      lookup_map = configMap.html_encode_map;
      regex = configMap.regex_encode_html;
    }
    map_match = function(match, name) {
      return lookup_map[match] || '';
    };
    return input_str.replace(regex, map_match);
  };

  getEmSize = function(elem) {
    return Number(window.getComputedStyle(elem, '').fontSize.match(/\d*\.?\d*/)[0]);
  };

  if (this.spa == null) {
    this.spa = {};
  }

  this.spa.util_b = {
    decodeHtml: decodeHtml,
    encodeHtml: encodeHtml,
    getEmSize: getEmSize
  };

}).call(this);
