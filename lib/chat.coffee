#chat.coffee


# ------------ BEGIN MODULE SCOPE VARIABLES --------------
socket      = require 'socket.io' 
crud        = require './crud'    
chat_adduser  = require './chat_adduser'

makeMongoId = crud.makeMongoId

chatterMap  = {}
# ------------- END MODULE SCOPE VARIABLES ---------------

# ---------------- BEGIN UTILITY METHODS -----------------
# emitUserList - broadcast user list to all connected clients
#
emitUserList =  ( io ) ->
  crud.read(
    'user',
    { is_online : true },
    {},
    ( result_list ) ->
      io
        .of( '/chat' )
        .emit( 'listchange', result_list )
      return
  )
  return

# signIn - update is_online property and chatterMap
#
signIn = ( io, user_map, socket ) ->
  crud.update(
    'user',
    { '_id'     : user_map._id },
    { is_online : true         },
    ( result_map ) ->
      emitUserList( io );
      user_map.is_online = true;
      socket.emit( 'userupdate', user_map );
      return
  )

  chatterMap[ user_map._id ] = socket
  socket.user_id = user_map._id
  return

# signOut - update is_online property and chatterMap
#
signOut =  ( io, user_id ) ->
  crud.update(
    'user',
    { '_id'     : user_id },
    { is_online : false   },
    ( result_list ) -> 
      emitUserList( io )
      return
  )
  delete chatterMap[ user_id ]
  return

# ----------------- END UTILITY METHODS ------------------


# ---------------- BEGIN PUBLIC METHODS ------------------



# begin connect
connect = ( server ) ->
  io = socket.listen( server )
  
  # begin make_connection
  make_connection = ( socket ) ->

    chat_adduser {
      socket 
      io 
      chatterMap
      emitUserList
      signIn
    }


    # Begin /updatechat/ message handler
    # Summary   : Handles messages for chat.
    # Arguments : A single chat_map object.
    #  chat_map should have the following properties:
    #    dest_id   = id of recipient
    #    dest_name = name of recipient
    #    sender_id = id of sender
    #    msg_text  = message text
    # Action    :
    #   If the recipient is online, the chat_map is sent to her.
    #   If not, a 'user has gone offline' message is
    #     sent to the sender.
    #
    socket.on 'updatechat',  ( chat_map ) ->
      if  chatterMap.hasOwnProperty( chat_map.dest_id ) 
        chatterMap[ chat_map.dest_id ]
          .emit( 'updatechat', chat_map );

      else 
        socket.emit( 'updatechat', {
          sender_id : chat_map.sender_id,
          msg_text  : chat_map.dest_name + ' has gone offline.'
        })
      
      return
    # End /updatechat/ message handler

    # Begin disconnect methods
    socket.on 'leavechat',  () ->
      console.log '** user %s logged out **', socket.user_id 
      signOut( io, socket.user_id )
      return

    socket.on 'disconnect', () ->
      console.log  '** user %s closed browser window or tab **', socket.user_id
      signOut( io, socket.user_id )
      return
    #/ End disconnect methods

    # Begin /updateavatar/ message handler
    # Summary   : Handles client updates of avatars
    # Arguments : A single avtr_map object.
    #   avtr_map should have the following properties:
    #   person_id = the id of the persons avatar to update
    #   css_map   = the css map for top, left, and
    #     background-color
    # Action    :
    #   This handler updates the entry in MongoDB, and then
    #   broadcasts the revised people list to all clients.
    #
    socket.on 'updateavatar',  ( avtr_map ) -> 
      crud.update(
        'user',
        { '_id'   : makeMongoId( avtr_map.person_id ) },
        { css_map : avtr_map.css_map },
        ( result_list ) ->
          emitUserList( io )
          return
      )
      return
    # End /updateavatar/ message handler


    return 
  # end make_connection



  # Begin io setup
  io.set( 'blacklist' , [] )
    .of( '/chat' )
    .on( 'connection',  make_connection)

  # End io setup

  return io

# end connect



chatObj = {
  connect
}

module.exports = chatObj