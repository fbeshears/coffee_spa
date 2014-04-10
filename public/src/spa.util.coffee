#spa.util.coffee

# Begin Public constructor /makeError/
# Purpose: a convenience wrapper to create an error object
# Arguments:
#   * name_text - the error name
#   * msg_text  - long error message
#   * data      - optional data attached to error object
# Returns  : newly constructed error object
# Throws   : none
#
makeError =  ( name_text, msg_text, data ) ->
  error         = new Error()
  error.name    = name_text
  error.message = msg_text

  error.data = data if data

  return error

# End Public constructor /makeError/

# Begin Public method /setConfigMap/
# Purpose: Common code to set configs in feature modules
# Arguments:
#   * input_map    - map of key-values to set in config
#   * settable_map - map of allowable keys to set
#   * config_map   - map to apply settings to
# Returns: true
# Throws : Exception if input key not allowed
#
setConfigMap =  ( arg_map ) ->
  input_map    = arg_map.input_map
  settable_map = arg_map.settable_map
  config_map   = arg_map.config_map


  for own key_name, key_value of input_map 

    if settable_map.hasOwnProperty( key_name ) 
      config_map[key_name] = key_value
    
    else 
      error = makeError( 'Bad Input',
        "Setting config key |#{key_name}| is not supported"
      )
      throw error

  return
    
# End Public method /setConfigMap/

@spa = {} if not @spa?

@spa.util = { 
  makeError 
  setConfigMap   
}
