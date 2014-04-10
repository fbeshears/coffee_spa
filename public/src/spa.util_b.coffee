###
spa.util_b.coffee
Avatar feature module
###


configMap = {
  regex_encode_html  : /[&"'><]/g,
  regex_encode_noamp : /["'><]/g,
  html_encode_map    : {
    '&' : '&#38;',
    '"' : '&#34;',
    "'" : '&#39;',
    '>' : '&#62;',
    '<' : '&#60;'
  }
}


configMap.encode_noamp_map = $.extend(
  {}, configMap.html_encode_map
)

delete configMap.encode_noamp_map['&']

#----------------- END MODULE SCOPE VARIABLES ---------------

#------------------- BEGIN UTILITY METHODS ------------------
# Begin decodeHtml
# Decodes HTML entities in a browser-friendly way
# See http:#stackoverflow.com/questions/1912501/\
#   unescape-html-entities-in-javascript
#
decodeHtml =  ( str ) ->
  return $('<div/>').html(str || '').text()

# End decodeHtml


# Begin encodeHtml
# This is single pass encoder for html entities and handles
# an arbitrary number of characters
#
encodeHtml = ( input_arg_str, exclude_amp ) ->
  input_str = String( input_arg_str )


  if  exclude_amp
    lookup_map = configMap.encode_noamp_map
    regex      = configMap.regex_encode_noamp
  
  else 
    lookup_map = configMap.html_encode_map
    regex      = configMap.regex_encode_html
  
  map_match = (match, name) ->
    return lookup_map[ match ] || ''

  return input_str.replace(regex, map_match)


# End encodeHtml

# Begin getEmSize
# returns size of ems in pixels
#
getEmSize =  ( elem ) ->
  return Number(
    window.getComputedStyle( elem, '' ).fontSize.match(/\d*\.?\d*/)[0]
  )

# End getEmSize


#------------------- END PUBLIC METHODS ---------------------

# export methods

@spa = {} if not @spa?

@spa.util_b = {
  decodeHtml 
  encodeHtml
  getEmSize
}
