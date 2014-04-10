#chat_adduser.coffee

crud        = require './crud'


chat_adduser = (arg_map) ->
  {socket, io, chatterMap, emitUserList, signIn} = arg_map


  # Begin /adduser/ message handler
  # Summary   : Provides sign in capability.
  # Arguments : A single user_map object.
  #   user_map should have the following properties:
  #     name    = the name of the user
  #     cid     = the client id
  # Action    :
  #   If a user with the provided username already exists
  #     in Mongo, use the existing user object and ignore
  #     other input.
  #   If a user with the provided username does not exist
  #     in Mongo, create one and use it.
  #   Send a 'userupdate' message to the sender so that
  #     a login cycle can complete.  Ensure the client id
  #     is passed back so the client can correlate the user,
  #     but do not store it in MongoDB.
  #   Mark the user as online and send the updated online
  #     user list to all clients, including the client that
  #     originated the 'adduser' message.
  #

  # Begin /adduser/ message handler
  socket.on 'adduser', ( user_map ) ->
    # begin read_callback
    read_callback = ( result_list ) ->
      cid = user_map.cid

      delete user_map.cid;

      # use existing user with provided name
      if ( result_list.length > 0 ) 
        result_map     = result_list[ 0 ]
        result_map.cid = cid
        signIn( io, result_map, socket )
      
      # create user with new name
      else 
        user_map.is_online = true
        crud.construct(
          'user',
          user_map,
          ( result_list ) ->
            result_map     = result_list[ 0 ]
            result_map.cid = cid
            chatterMap[ result_map._id ] = socket
            socket.user_id = result_map._id
            socket.emit( 'userupdate', result_map )
            emitUserList( io )
            return
        )

      return
    # end read_callback

    crud.read(
      'user',
      { name : user_map.name },
      {},
      read_callback
    ) 
    return

  # End /adduser/ message handler



module.exports = chat_adduser
