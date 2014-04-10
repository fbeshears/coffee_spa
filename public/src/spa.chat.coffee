#spa.chat.coffee

#Chat feature module for SPA



#---------------- BEGIN MODULE SCOPE VARIABLES --------------

configMap = {
  main_html : """
    <div class="spa-chat">
      <div class="spa-chat-head">
        <div class="spa-chat-head-toggle">+</div>
        <div class="spa-chat-head-title">
          Chat
        </div>
      </div>
      <div class="spa-chat-closer">x</div>
      <div class="spa-chat-sizer">
        <div class="spa-chat-list">
            <div class="spa-chat-list-box"></div>
        </div>
        <div class="spa-chat-msg">
          <div class="spa-chat-msg-log"></div>
          <div class="spa-chat-msg-in">
            <form class="spa-chat-msg-form">
              <input type="text"/>
              <input type="submit" style="display:none"/>
              <div class="spa-chat-msg-send">
                send
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  settable_map : {
    slider_open_time    : true
    slider_close_time   : true
    slider_opened_em    : true
    slider_closed_em    : true
    slider_opened_title : true
    slider_closed_title : true
    chat_model          : true
    people_model        : true
    set_chat_anchor     : true
  },
  slider_open_time      : 250
  slider_close_time     : 250
  slider_opened_em      : 18
  slider_closed_em      : 2
  slider_opened_min_em  : 10
  window_height_min_em  : 20,
  slider_opened_title   : 'Tap to close'
  slider_closed_title   : 'Tap to open'

  chat_model      : null
  people_model    : null
  set_chat_anchor : null
}

stateMap  = {
  $append_target   : null
  position_type    : 'closed'
  px_per_em        : 0
  slider_hidden_px : 0
  slider_closed_px : 0
  slider_opened_px : 0
}

jqueryMap = {}


#----------------- END MODULE SCOPE VARIABLES ---------------



#--------------------- BEGIN DOM METHODS --------------------
# Begin DOM method /setJqueryMap/
setJqueryMap = ->
  $append_target = stateMap.$append_target
  $slider        = $append_target.find( '.spa-chat' )

  jqueryMap = {
    $slider : $slider
    $head   : $slider.find( '.spa-chat-head' )
    $toggle : $slider.find( '.spa-chat-head-toggle' )
    $title  : $slider.find( '.spa-chat-head-title' )
    $sizer  : $slider.find( '.spa-chat-sizer' )
    $list_box : $slider.find( '.spa-chat-list-box' )
    $msg_log  : $slider.find( '.spa-chat-msg-log' )
    $msg_in   : $slider.find( '.spa-chat-msg-in' )
    $input    : $slider.find( '.spa-chat-msg-in input[type=text]')
    $send     : $slider.find( '.spa-chat-msg-send' )
    $form     : $slider.find( '.spa-chat-msg-form' )
    $window   : $(window)
  };
  return

# End DOM method /setJqueryMap/

# Begin DOM method /setPxSizes/
setPxSizes =  () ->
  px_per_em = spa.util_b.getEmSize( jqueryMap.$slider.get(0) )
  window_height_em = Math.floor( (jqueryMap.$window.height() / px_per_em) + 0.5 )

  if window_height_em > configMap.window_height_min_em
    opened_height_em = configMap.slider_opened_em
  else
    opened_height_em = configMap.slider_opened_min_em

  #opened_height_em = configMap.slider_opened_em

  stateMap.px_per_em        = px_per_em
  stateMap.slider_closed_px = configMap.slider_closed_em * px_per_em
  stateMap.slider_opened_px = opened_height_em * px_per_em

  jqueryMap.$sizer.css {
    height : ( opened_height_em - 2 ) * px_per_em
  }
  return

# End DOM method /setPxSizes/

# Begin public DOM method /setSliderPosition/
# Example   : spa.chat.setSliderPosition( 'closed' );
# Purpose   : Move the chat slider to the requested position
# Arguments :
#   * position_type - enum('closed', 'opened', or 'hidden')
#   * callback - optional callback to be run end at the end
#     of slider animation.  The callback receives a jQuery
#     collection representing the slider div as its single
#     argument
# Action    :
#   This method moves the slider into the requested position.
#   If the requested position is the current position, it
#   returns true without taking further action
# Returns   :
#   * true  - The requested position was achieved
#   * false - The requested position was not achieved
# Throws    : none
#
setSliderPosition =  ( position_type, callback ) ->

  # position type of 'opened' is not allowed for anon user;
  # therefore we simply return false; the shell will fix the
  # uri and try again.
  return false if  position_type == 'opened' && configMap.people_model.get_user().get_is_anon()


  # return true if slider already in requested position
  if  stateMap.position_type == position_type 
    jqueryMap.$input.focus() if  position_type == 'opened' 
    return true 

  # prepare animate parameters
  switch  position_type 
    when 'opened' 
      height_px    = stateMap.slider_opened_px
      animate_time = configMap.slider_open_time
      slider_title = configMap.slider_opened_title
      toggle_text  = '='
      jqueryMap.$input.focus()

    when 'hidden' 
      height_px    = 0
      animate_time = configMap.slider_open_time
      slider_title = ''
      toggle_text  = '+'
    

    when 'closed' 
      height_px    = stateMap.slider_closed_px
      animate_time = configMap.slider_close_time
      slider_title = configMap.slider_closed_title
      toggle_text  = '+'
    

    # bail for unknown position_type
    else  
      return false
 
  do_animate = -> 
    jqueryMap.$toggle.prop( 'title', slider_title )
    jqueryMap.$toggle.text( toggle_text )
    stateMap.position_type = position_type
    callback( jqueryMap.$slider ) if callback?
    return
  

  # animate slider position change
  stateMap.position_type = ''
  jqueryMap.$slider.animate({ height : height_px }, animate_time, do_animate )

  return true

# End public DOM method /setSliderPosition/

# Begin private DOM methods to manage chat message
scrollChat = () ->
  $msg_log = jqueryMap.$msg_log
  scrollTop = $msg_log.prop( 'scrollHeight' ) - $msg_log.height()
  $msg_log.animate({scrollTop: scrollTop}, 150 )
  return


writeChat =  ( person_name, text, is_user ) ->
  msg_class = if is_user then 'spa-chat-msg-log-me' else 'spa-chat-msg-log-msg'
  div_body = "#{spa.util_b.encodeHtml(person_name)}: #{spa.util_b.encodeHtml(text)}"

  jqueryMap.$msg_log.append("<div class='#{msg_class}'> #{div_body} </div>")

  scrollChat()
  return


writeAlert =  ( alert_text ) ->
  jqueryMap.$msg_log.append(
    """
    <div class='spa-chat-msg-log-alert'>
      #{spa.util_b.encodeHtml(alert_text)}
    </div>
    """
  )
  scrollChat()
  return

clearChat =  ()  ->
  jqueryMap.$msg_log.empty()
  return

# End private DOM methods to manage chat message

#---------------------- END DOM METHODS ---------------------

#------------------- BEGIN EVENT HANDLERS -------------------
onTapToggle = ( event ) ->
  set_chat_anchor = configMap.set_chat_anchor

  if stateMap.position_type == 'opened' 
    set_chat_anchor( 'closed' )
  
  else if stateMap.position_type == 'closed'
    set_chat_anchor( 'opened' )
  
  return false

onSubmitMsg = ( event ) ->
  msg_text = jqueryMap.$input.val()
  return false if  msg_text.trim() == '' 
  configMap.chat_model.send_msg( msg_text )
  jqueryMap.$input.focus()
  jqueryMap.$send.addClass( 'spa-x-select' )
  remClass = ->
    jqueryMap.$send.removeClass( 'spa-x-select' )
    return
  setTimeout remClass, 250
  return false


onTapList = ( event ) ->
  $tapped  = $( event.elem_target )
  return false if not $tapped.hasClass('spa-chat-list-name') 

  chatee_id = $tapped.attr( 'data-id' );
  return false if not chatee_id 

  configMap.chat_model.set_chatee( chatee_id )
  return false;


onSetchatee =  ( event, arg_map ) ->
  new_chatee = arg_map.new_chatee
  old_chatee = arg_map.old_chatee

  jqueryMap.$input.focus()
  if not new_chatee 
    if old_chatee 
      writeAlert( old_chatee.name + ' has left the chat' ) 
    else 
      writeAlert( 'Your friend has left the chat' )
    
    jqueryMap.$title.text( 'Chat' )
    return false


  jqueryMap.$list_box
    .find( '.spa-chat-list-name' )
    .removeClass( 'spa-x-select' )
    .end()
    .find( "[data-id=#{arg_map.new_chatee.id}]")
    .addClass( 'spa-x-select' )

  writeAlert( 'Now chatting with ' + arg_map.new_chatee.name )
  jqueryMap.$title.text( 'Chat with ' + arg_map.new_chatee.name )
  return true


onListchange =  ( event ) ->
  list_html = String()
  people_db = configMap.people_model.get_db()
  chatee    = configMap.chat_model.get_chatee()


  do_person = ( person, idx ) -> 

    return true if person.get_is_anon() or person.get_is_user()
 
    if  chatee and chatee.id == person.id  
      select_class  = 'spa-chat-list-name spa-x-select'
    else
      select_class = 'spa-chat-list-name'

    list_html += """
      <div class='#{select_class}' data-id='#{person.id}'>
        #{spa.util_b.encodeHtml( person.name )}
      </div>
      """
    return

  people_db().each(do_person)

  if not list_html 
    list_html = """
      <div class='spa-chat-list-note'>
        To chat alone is the fate of all great souls...<br><br>
        No one is online
      </div>
      """
    clearChat()

  jqueryMap.$list_box.html( list_html )
  return

onUpdatechat =  ( event, msg_map ) ->

  sender_id = msg_map.sender_id
  msg_text  = msg_map.msg_text
  chatee    = configMap.chat_model.get_chatee() || {}
  sender    = configMap.people_model.get_by_cid( sender_id )

  if not sender 
    writeAlert( msg_text )
    return false


  is_user = sender.get_is_user()

  if not ( is_user || sender_id == chatee.id ) 
    configMap.chat_model.set_chatee( sender_id )


  writeChat( sender.name, msg_text, is_user )

  if  is_user 
    jqueryMap.$input.val( '' )
    jqueryMap.$input.focus()
  

  return

onLogin =  ( event, login_user ) ->
  configMap.set_chat_anchor( 'opened' )
  return


onLogout =  ( event, logout_user ) ->
  configMap.set_chat_anchor( 'closed' )
  jqueryMap.$title.text( 'Chat' )
  clearChat()
  return

#-------------------- END EVENT HANDLERS --------------------

#------------------- BEGIN PUBLIC METHODS -------------------
# Begin public method /configModule/
# Example   : spa.chat.configModule({ slider_open_em : 18 });
# Purpose   : Configure the module prior to initialization
# Arguments :
#   * set_chat_anchor - a callback to modify the URI anchor to
#     indicate opened or closed state. This callback must return
#     false if the requested state cannot be met
#   * chat_model - the chat model object provides methods
#       to interact with our instant messaging
#   * people_model - the people model object which provides
#       methods to manage the list of people the model maintains
#   * slider_* settings. All these are optional scalars.
#       See mapConfig.settable_map for a full list
#       Example: slider_open_em is the open height in em's
# Action    :
#   The internal configuration data structure (configMap) is
#   updated with provided arguments. No other actions are taken.
# Returns   : true
# Throws    : JavaScript error object and stack trace on
#             unacceptable or missing arguments

configModule = ( input_map ) -> 
  spa.util.setConfigMap {
    input_map  : input_map
    settable_map : configMap.settable_map
    config_map  : configMap
  }
  return true

# End public method /configModule/

# Begin public method /initModule/
# Example    : spa.chat.initModule( $('#div_id') );
# Purpose    :
#   Directs Chat to offer its capability to the user
# Arguments  :
#   * $append_target (example: $('#div_id')).
#     A jQuery collection that should represent
#     a single DOM container
# Action     :
#   Appends the chat slider to the provided container and fills
#   it with HTML content.  It then initializes elements,
#   events, and handlers to provide the user with a chat-room
#   interface
# Returns    : true on success, false on failure
# Throws     : none
#
initModule =  ( $append_target ) ->

  #load chat slider html and jquery cache

  stateMap.$append_target = $append_target
  $append_target.append( configMap.main_html )
  setJqueryMap()
  setPxSizes()

  # initialize chat slider to default title and state
  jqueryMap.$toggle.prop( 'title', configMap.slider_closed_title )
  stateMap.position_type = 'closed'

  # Have $list_box subscribe to jQuery global events
  $list_box = jqueryMap.$list_box
  $.gevent.subscribe( $list_box, 'spa-listchange', onListchange )
  $.gevent.subscribe( $list_box, 'spa-setchatee',  onSetchatee  )
  $.gevent.subscribe( $list_box, 'spa-updatechat', onUpdatechat )
  $.gevent.subscribe( $list_box, 'spa-login',      onLogin      )
  $.gevent.subscribe( $list_box, 'spa-logout',     onLogout     )

  # bind user input events
  jqueryMap.$head.bind(     'utap', onTapToggle )
  jqueryMap.$list_box.bind( 'utap', onTapList   )
  jqueryMap.$send.bind(     'utap', onSubmitMsg )
  jqueryMap.$form.bind(   'submit', onSubmitMsg )

  return true

# End public method /initModule/

# Begin public method /removeSlider/
# Purpose    :
#   * Removes chatSlider DOM element
#   * Reverts to initial state
#   * Removes pointers to callbacks and other data
# Arguments  : none
# Returns    : true
# Throws     : none

removeSlider = ->
  # unwind initialization and state
  # remove DOM container; this removes event bindings too
  if  jqueryMap.$slider
    jqueryMap.$slider.remove()
    jqueryMap = {}
  
  stateMap.$append_target = null
  stateMap.position_type  = 'closed'

  # unwind key configurations
  configMap.chat_model      = null
  configMap.people_model    = null
  configMap.set_chat_anchor = null

  return true

# End public method /removeSlider/

# Begin public method /handleResize/
# Purpose    :
#   Given a window resize event, adjust the presentation
#   provided by this module if needed
# Actions    :
#   If the window height or width falls below
#   a given threshold, resize the chat slider for the
#   reduced window size.
# Returns    : Boolean
#   * false - resize not considered
#   * true  - resize considered
# Throws     : none
#
handleResize = ->
  # don't do anything if we don't have a slider container
  return false if not jqueryMap.$slider?

  setPxSizes()
  if  stateMap.position_type == 'opened' 
    jqueryMap.$slider.css { height : stateMap.slider_opened_px }
  
  return true;

# End public method /handleResize/

#------------------- END PUBLIC METHODS ---------------------


@spa = {} if not @spa?

@spa.chat = { 
  setSliderPosition
  configModule 
  initModule   
  removeSlider
  handleResize
}
