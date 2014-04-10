###
spa.model.coffee
###


configMap = { anon_id : 'a0' }

stateMap  = {
  anon_user      : null
  cid_serial     : 0
  is_connected   : false
  people_cid_map : {}
  people_db      : TAFFY()
  user           : null
}

isFakeData = false

# The people object API
# ---------------------
# The people object is available at spa.model.people.
# The people object provides methods and events to manage
# a collection of person objects. Its public methods include:
#   * get_user() - return the current user person object.
#     If the current user is not signed-in, an anonymous person
#     object is returned.
#   * get_db() - return the TaffyDB database of all the person
#     objects - including the current user - presorted.
#   * get_by_cid( <client_id> ) - return a person object with
#     provided unique id.
#   * login( <user_name> ) - login as the user with the provided
#     user name. The current user object is changed to reflect
#     the new identity. Successful completion of login
#     publishes a 'spa-login' global custom event.
#   * logout()- revert the current user object to anonymous.
#     This method publishes a 'spa-logout' global custom event.
#
# jQuery global custom events published by the object include:
#   * spa-login - This is published when a user login process
#     completes. The updated user object is provided as data.
#   * spa-logout - This is published when a logout completes.
#     The former user object is provided as data.
#
# Each person is represented by a person object.
# Person objects provide the following methods:
#   * get_is_user() - return true if object is the current user
#   * get_is_anon() - return true if object is anonymous
#
# The attributes for a person object include:
#   * cid - string client id. This is always defined, and
#     is only different from the id attribute
#     if the client data is not synced with the backend.
#   * id - the unique id. This may be undefined if the
#     object is not synced with the backend.
#   * name - the string name of the user.
#   * css_map - a map of attributes used for avatar
#     presentation.
#
makeCid = ->
  return 'c' + String( stateMap.cid_serial++ );


clearPeopleDb = ->
  user = stateMap.user
  stateMap.people_db      = TAFFY()
  stateMap.people_cid_map = {}
  if user
    stateMap.people_db.insert( user )
    stateMap.people_cid_map[ user.cid ] = user
  return

completeLogin =  ( user_list ) ->
  user_map = user_list[ 0 ]
  delete stateMap.people_cid_map[ user_map.cid ]
  stateMap.user.cid     = user_map._id
  stateMap.user.id      = user_map._id
  stateMap.user.css_map = user_map.css_map
  stateMap.people_cid_map[ user_map._id ] = stateMap.user

  chat.join()
  #When we add chat, we should join here
  $.gevent.publish( 'spa-login', [ stateMap.user ] )
  return


class Person
  constructor: (person_map) ->
    @cid        = person_map.cid
    @css_map    = person_map.css_map
    @name       = person_map.name
    @id         = person_map.id if person_map.id?

    if @cid is undefined || not @name
      throw new Error('client id and name required')

  get_is_user:  () ->
    return @cid == stateMap.user.cid
  

  get_is_anon:  () ->
    return @cid == stateMap.anon_user.cid


makePerson = (person_map) ->
  person = new Person(person_map)

  stateMap.people_cid_map[person.cid] = person

  stateMap.people_db.insert( person )

  return person


removePerson =  ( person ) ->
  return false if not person

  #cannot remove anonymous person
  return false if person.id is configMap.anon_id 

  stateMap.people_db({ cid : person.cid }).remove()

  delete stateMap.people_cid_map[ person.cid ] if person.cid?

  return true




people = {
  get_db: ->
    return stateMap.people_db

  get_by_cid: (cid) ->
    return stateMap.people_cid_map[cid]

  get_user: ->
    return stateMap.user

  login:  ( name ) ->
    sio = if isFakeData then spa.fake.mockSio else spa.data.getSio()

    stateMap.user = makePerson {
      cid     : makeCid(),
      css_map : {top : 25, left : 25, 'background-color':'#8f8'},
      name    : name
    }

    sio.on 'userupdate', completeLogin 

    sio.emit 'adduser', {
      cid     : stateMap.user.cid,
      css_map : stateMap.user.css_map,
      name    : stateMap.user.name
    }

    return


  logout:  ->
    user = stateMap.user

    chat._leave()
    # when we add chat, we should leave the chatroom here
    #is_removed    = removePerson( user ) # removed in 6.3.4  also note that removePerson is not used now
    stateMap.user = stateMap.anon_user

    clearPeopleDb()                                       # clearPeopleDb() called starting in 6.3.4

    $.gevent.publish( 'spa-logout', [ user ] )
    return                                                # now don't return is_removed


}

# The chat object API
# -------------------
# The chat object is available at spa.model.chat.
# The chat object provides methods and events to manage
# chat messaging. Its public methods include:
#  * join() - joins the chat room. This routine sets up
#    the chat protocol with the backend including publishers
#    for 'spa-listchange' and 'spa-updatechat' global
#    custom events. If the current user is anonymous,
#    join() aborts and returns false.
#  * get_chatee() - return the person object with whom the user
#    is chatting with. If there is no chatee, null is returned.
#  * set_chatee( <person_id> ) - set the chatee to the person
#    identified by person_id. If the person_id does not exist
#    in the people list, the chatee is set to null. If the
#    person requested is already the chatee, it returns false.
#    It publishes a 'spa-setchatee' global custom event.
#  * send_msg( <msg_text> ) - send a message to the chatee.
#    It publishes a 'spa-updatechat' global custom event.
#    If the user is anonymous or the chatee is null, it
#    aborts and returns false.
#  * update_avatar( <update_avtr_map> ) - send the
#    update_avtr_map to the backend. This results in an
#    'spa-listchange' event which publishes the updated
#    people list and avatar information (the css_map in the
#    person objects). The update_avtr_map must have the form
#    { person_id : person_id, css_map : css_map }.
  
#
# jQuery global custom events published by the object include:
#  * spa-setchatee - This is published when a new chatee is
#    set. A map of the form:
#      { old_chatee : <old_chatee_person_object>,
#        new_chatee : <new_chatee_person_object>
#      }
#    is provided as data.
#  * spa-listchange - This is published when the list of
#    online people changes in length (i.e. when a person
#    joins or leaves a chat) or when their contents change
#    (i.e. when a person's avatar details change).
#    A subscriber to this event should get the people_db
#    from the people model for the updated data.
#  * spa-updatechat - This is published when a new message
#    is received or sent. A map of the form:
#      { dest_id   : <chatee_id>,
#        dest_name : <chatee_name>,
#        sender_id : <sender_id>,
#        msg_text  : <message_content>
#      }
#    is provided as data.
#

#----------- BEGIN CHAT CLOSURE ----------------
chat =  do () ->

  chatee = null

 # Begin internal methods


  _update_list = ( arg_list ) ->
    people_list      = arg_list[ 0 ]
    is_chatee_online = false;

    do_updates = (person_map) ->
      if stateMap.user and stateMap.user.id is person_map._id 
          stateMap.user.css_map = person_map.css_map

      else

        make_person_map = {
          cid     : person_map._id,
          css_map : person_map.css_map,
          id      : person_map._id,
          name    : person_map.name

        }

        person = makePerson(make_person_map)

        if chatee && chatee.id is make_person_map.id
          is_chatee_online = true
          chatee = person


      return


    clearPeopleDb()

    for person_map in people_list
      do_updates(person_map) if  person_map.name


    stateMap.people_db.sort( 'name' )


    # If chatee is no longer online, we unset the chatee
    # which triggers the 'spa-setchatee' global event
    set_chatee('') if chatee and not is_chatee_online 

    return

  _publish_listchange =  ( arg_list ) ->
    _update_list( arg_list )
    $.gevent.publish( 'spa-listchange', [ arg_list ] )
    return

  _publish_updatechat =  ( arg_list ) ->
    msg_map = arg_list[ 0 ]

    if not chatee
      set_chatee( msg_map.sender_id )

    else if  msg_map.sender_id != stateMap.user.id and msg_map.sender_id != chatee.id
      set_chatee( msg_map.sender_id )


    $.gevent.publish( 'spa-updatechat', [ msg_map ] )

    return

 # End internal methods

  _leave_chat =  () ->
    sio = if isFakeData then spa.fake.mockSio else spa.data.getSio()
    stateMap.is_connected = false
    sio.emit( 'leavechat' ) if  sio 
    return

  get_chatee =  () -> return chatee

  join_chat  =  () ->

    return false if ( stateMap.is_connected ) 

    if stateMap.user.get_is_anon() 
      console.warn( 'User must be defined before joining chat')
      return false
  

    sio = if isFakeData then spa.fake.mockSio else spa.data.getSio()
    sio.on( 'listchange', _publish_listchange )
    sio.on( 'updatechat', _publish_updatechat )
    stateMap.is_connected = true
    return true

  send_msg =  ( msg_text ) ->

    sio = if isFakeData then spa.fake.mockSio else spa.data.getSio()

    return false if not sio 
    return false if not ( stateMap.user and chatee ) 

    msg_map = {
      dest_id   : chatee.id,
      dest_name : chatee.name,
      sender_id : stateMap.user.id,
      msg_text  : msg_text
    }

    # we published updatechat so we can show our outgoing messages
    _publish_updatechat( [ msg_map ] )
    sio.emit( 'updatechat', msg_map )
    return true


  set_chatee =  ( person_id ) ->
    new_chatee  = stateMap.people_cid_map[ person_id ]
    if not new_chatee 
      new_chatee = null
    else if  chatee and chatee.id is new_chatee.id 
      return false;


    $.gevent.publish( 'spa-setchatee',
      { old_chatee : chatee, new_chatee : new_chatee }
    )
    chatee = new_chatee
    return true

  # avatar_update_map should have the form:
  # { person_id : <string>, css_map : {
  #   top : <int>, left : <int>,
  #   'background-color' : <string>
  # }};
  #

  update_avatar = ( avatar_update_map ) ->
    sio = if isFakeData then spa.fake.mockSio else spa.data.getSio()

    sio.emit( 'updateavatar', avatar_update_map ) if (sio) 

    return

  return {
    _leave        : _leave_chat,
    get_chatee    : get_chatee,
    join          : join_chat,
    send_msg      : send_msg,
    set_chatee    : set_chatee,
    update_avatar : update_avatar
  }


#----------- END CHAT CLOSURE ----------------

initModule =  ->

  # initialize anonymous person
  stateMap.anon_user = makePerson {
    cid   : configMap.anon_id
    id    : configMap.anon_id
    name  : 'anonymous'
  }

  stateMap.user = stateMap.anon_user;

  return


@spa = {} if not @spa?

@spa.model = {
  initModule
  chat
  people
}
