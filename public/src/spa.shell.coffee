#spa.shell.coffee


#---------------- BEGIN MODULE SCOPE VARIABLES --------------
configMap = {
  anchor_schema_map: {
    chat: {opened: true, closed: true}
  },

  resize_interval: 200,

  main_html: """
    <div class="spa-shell-head">
      <div class="spa-shell-head-logo">
        <h1>SPA</h1>
        <p>javascript end to end</p>
      </div>
      <div class="spa-shell-head-acct"></div>
    </div>
    <div class="spa-shell-main">
      <div class="spa-shell-main-nav"></div>
      <div class="spa-shell-main-content"></div>
    </div>
    <div class="spa-shell-foot"></div>
    <div class="spa-shell-modal"></div>
    """
}

stateMap = {
  $container    : undefined
  anchor_map    : {}
  resize_idto   : undefined
}

jqueryMap = {}

#----------------- END MODULE SCOPE VARIABLES ---------------

#------------------- BEGIN UTILITY METHODS ------------------
# Returns copy of stored anchor map; minimizes overhead

copyAnchorMap = ->
  return $.extend( true, {}, stateMap.anchor_map )



#-------------------- END UTILITY METHODS -------------------

#--------------------- BEGIN DOM METHODS --------------------
# Begin DOM method /setJqueryMap/

setJqueryMap = ->
  $container = stateMap.$container
  jqueryMap = {
    $container : $container
    $acct      : $container.find('.spa-shell-head-acct')
    $nav       : $container.find('.spa-shell-main-nav')
  }
  return
# End DOM method /setJqueryMap/


# Begin DOM method /mergeChangeIntoAnchorMap/
# Arguments:
#   * arg_map - The map describing what part of the URI anchor
#     we want changed.
#   See uriAnchor for a discussion of encoding.
# Returns  : revised anchor map
#
#   This method
#     * Creates a copy of this map using copyAnchorMap().
#     * Modifies the key-values using arg_map.
#     * Manages the distinction between independent
#       and dependent values in the encoding.
mergeChangeIntoAnchorMap = (arg_map) ->
  anchor_map_revise = copyAnchorMap()
  for own key_name, key_value of arg_map 
      # skip dependent keys during iteration
     if key_name[0] != '_' 
        # update independent key value
        anchor_map_revise[key_name] = key_value

        # update matching dependent key
        key_name_dep = '_' + key_name
        if arg_map[key_name_dep] 
          anchor_map_revise[key_name_dep] = arg_map[key_name_dep]
        else 
          delete anchor_map_revise[key_name_dep]
          delete anchor_map_revise['_s' + key_name_dep]  

  return anchor_map_revise
# End DOM method /mergeChangeIntoAnchorMap/

# Begin DOM method /changeAnchorPart/
# Purpose  : Changes part of the URI anchor component
# Arguments:
#   * arg_map - The map describing what part of the URI anchor
#     we want changed.
# Returns  : boolean
#   * true  - the Anchor portion of the URI was update
#   * false - the Anchor portion of the URI could not be updated
# Action   :
#   The current anchor rep stored in stateMap.anchor_map.
#   This method
#     * Attempts to change the URI using uriAnchor.
#     * Returns true on success, and false on failure.
#


changeAnchorPart = ( arg_map ) -> 
    
  anchor_map_revise = mergeChangeIntoAnchorMap( arg_map )

  # Begin attempt to update URI; revert if not successful
  try 
    $.uriAnchor.setAnchor( anchor_map_revise )
  
  catch error 
    # replace URI with existing state
    $.uriAnchor.setAnchor( stateMap.anchor_map, null, true )
    return false
  
  # End attempt to update URI...

  return true

# End DOM method /changeAnchorPart/
#--------------------- END DOM METHODS ----------------------

#------------------- BEGIN EVENT HANDLERS -------------------
# Begin Event handler /onHashchange/
# Purpose  : Handles the hashchange event
# Arguments:
#   * event - jQuery event object.
# Settings : none
# Returns  : false
# Action   :
#   * Parses the URI anchor component
#   * Compares proposed application state with current
#   * Adjust the application only where proposed state
#     differs from existing
#
onHashchange =  ( event ) -> 
  is_ok = true
  anchor_map_previous = copyAnchorMap()

  # attempt to parse anchor
  try 
    anchor_map_proposed = $.uriAnchor.makeAnchorMap()
  catch  error 
    $.uriAnchor.setAnchor( anchor_map_previous, null, true )
    return false

  stateMap.anchor_map = anchor_map_proposed

  # convenience vars
  _s_chat_previous = anchor_map_previous._s_chat
  _s_chat_proposed = anchor_map_proposed._s_chat

  revert_anchor = ->
    if anchor_map_previous
      $.uriAnchor.setAnchor( anchor_map_previous, null, true )
      stateMap.anchor_map = anchor_map_previous
    
    else 
      delete anchor_map_proposed.chat
      $.uriAnchor.setAnchor( anchor_map_proposed, null, true )

    return

  adjust_chat = ->
    s_chat_proposed = anchor_map_proposed.chat
    switch  s_chat_proposed 
      when 'opened'   
         is_ok = spa.chat.setSliderPosition( 'opened' )
      when 'closed' 
         is_ok = spa.chat.setSliderPosition( 'closed' )
      else
        spa.chat.setSliderPosition( 'closed' )
        delete anchor_map_proposed.chat
        $.uriAnchor.setAnchor( anchor_map_proposed, null, true )

    return



  # Begin adjust chat component if changed
  if !anchor_map_previous || _s_chat_previous != _s_chat_proposed
    adjust_chat()
  # End adjust chat component if changed

  # Begin revert anchor if slider change denied
  revert_anchor() if not is_ok 
  # End revert anchor if slider change denied

  return false

# End Event handler /onHashchange/

# Begin Event handler /onResize/
onResize = ->
  return true if stateMap.resize_idto

  spa.chat.handleResize()

  do_resize = ->
    stateMap.resize_idto = undefined
    return

  stateMap.resize_idto = setTimeout( do_resize, configMap.resize_interval )

  return true

# End Event handler /onResize/

onTapAcct =  ( event ) -> 
  user = spa.model.people.get_user();
  if user.get_is_anon() 
    user_name = prompt( 'Please sign-in' )
    spa.model.people.login( user_name )
    jqueryMap.$acct.text( '... processing ...' )
  else 
   spa.model.people.logout();
  
  return false;


onLogin =  ( event, login_user ) -> 
  jqueryMap.$acct.text( login_user.name )
  return

onLogout =  ( event, logout_user ) -> 
  jqueryMap.$acct.text( 'Please sign-in' )
  return


#-------------------- END EVENT HANDLERS --------------------

#---------------------- BEGIN CALLBACKS ---------------------
# Begin callback method /setChatAnchor/
# Example  : setChatAnchor( 'closed' );
# Purpose  : Change the chat component of the anchor
# Arguments:
#   * position_type - may be 'closed' or 'opened'
# Action   :
#   Changes the URI anchor parameter 'chat' to the requested
#   value if possible.
# Returns  :
#   * true  - requested anchor part was updated
#   * false - requested anchor part was not updated
# Throws   : none
#
setChatAnchor = ( position_type ) ->
  return changeAnchorPart { chat : position_type }

# End callback method /setChatAnchor/
#----------------------- END CALLBACKS ----------------------


#------------------- BEGIN PUBLIC METHODS -------------------
# Begin Public method /initModule/
# Example  : spa.shell.initModule( $('#app_div_id') );
# Purpose  :
#   Directs the Shell to offer its capability to the user
# Arguments :
#   * $container (example: $('#app_div_id')).
#     A jQuery collection that should represent 
#     a single DOM container
# Action    :
#   Populates $container with the shell of the UI
#   and then configures and initializes feature modules.
#   The Shell is also responsible for browser-wide issues
#   such as URI anchor and cookie management.
# Returns   : none 
# Throws    : none
#

initModule = ($container) ->
  stateMap.$container = $container
  $container.html( configMap.main_html )
  setJqueryMap()


  # configure uriAnchor to use our schema
  $.uriAnchor.configModule {
    schema_map : configMap.anchor_schema_map
  }

  # configure and initialize feature modules
  spa.chat.configModule {
    set_chat_anchor : setChatAnchor
    chat_model      : spa.model.chat
    people_model    : spa.model.people
  }
  
  spa.chat.initModule jqueryMap.$container 


  spa.avtr.configModule {
    chat_model   : spa.model.chat,
    people_model : spa.model.people
  }

  spa.avtr.initModule jqueryMap.$nav 

  # Handle URI anchor change events.
  # This is done /after/ all feature modules are configured
  # and initialized, otherwise they will not be ready to handle
  # the trigger event, which is used to ensure the anchor
  # is considered on-load
  #
  $(window)
    .bind('resize', onResize)
    .bind( 'hashchange', onHashchange )
    .trigger( 'hashchange' ) 

  $.gevent.subscribe( $container, 'spa-login',  onLogin  )
  $.gevent.subscribe( $container, 'spa-logout', onLogout )

  jqueryMap.$acct
    .text( 'Please sign-in')
    .bind( 'utap', onTapAcct )

  return


# End PUBLIC method /initModule/

#------------------- END PUBLIC METHODS ---------------------

@spa = {} if not @spa?

@spa.shell = { initModule : initModule }
