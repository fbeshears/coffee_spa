###
spa.fake.coffee
Avatar feature module
###

fakeIdSerial = 5

makeFakeId =  () ->
  return 'id_' + String( fakeIdSerial++ )


peopleList = [
  { 
    name : 'Betty', _id: 'id_01',
    css_map: { 
      top: 20, left: 20,
      'background-color': 'rgb( 128, 128, 128)'
    }
  },
  { 
    name: 'Mike',  _id: 'id_02',
    css_map: { 
      top: 60, left: 20,
      'background-color': 'rgb( 128, 255, 128)'
    }
  },
  { 
    name: 'Pebbles', _id: 'id_03',
    css_map: { 
      top: 100, left: 20,
      'background-color': 'rgb( 128, 192, 192)'
    }
  },
  { 
    name: 'Wilma',  _id: 'id_04',
    css_map: { 
      top: 140, left: 20,
      'background-color': 'rgb( 192, 128, 128)'
    }
  }
]


#--------------- BEGIN mockSio -----------------

mockSio = do ( ) ->

  listchange_idto = undefined
  callback_map = {}



  on_sio =  ( msg_type, callback ) -> 
    callback_map[ msg_type ] = callback;
    return

  emit_sio =  ( msg_type, data ) ->

    do_adduser = ->
      person_map = {  
        _id     : makeFakeId()
        name    : data.name
        css_map : data.css_map
      }
      peopleList.push( person_map )
      callback_map.userupdate( [person_map] )
      return

    do_updatechat = ->
      user = spa.model.people.get_user()
      person_map = {
        dest_id   : user.id,
        dest_name : user.name,
        sender_id : data.dest_id,
        msg_text  : 'Thanks for the note, ' + user.name
      }
      callback_map.updatechat([person_map])

    # respond to 'adduser' event with 'userupdate'
    # callback after a 3s delay
    #
    if  msg_type is 'adduser' and callback_map.userupdate
      setTimeout do_adduser ,  3000

    # Respond to 'updatechat' event with an 'updatechat'
    # callback after a 2s delay. Echo back user info.
    else if  msg_type is 'updatechat' && callback_map.updatechat 
      setTimeout( do_updatechat, 2000)


    else if msg_type is 'leavechat' 
      # reset login status
      delete callback_map.listchange
      delete callback_map.updatechat

      if  listchange_idto 
        clearTimeout( listchange_idto )
        listchange_idto = undefined

      send_listchange()

    # simulate send of 'updateavatar' message and data to server
    else if  msg_type is 'updateavatar' and callback_map.listchange  
      # simulate receipt of 'listchange' message


      for person in peopleList
        if person._id is data.person_id
          person.css_map = data.css_map
          break

      # execute callback for the 'listchange' message
      callback_map.listchange([ peopleList ])
 

    return



  emit_mock_msg =  () ->
    do_updatechat = () ->
      if not callback_map.updatechat 
        emit_mock_msg()
      else
        user = spa.model.people.get_user();
        person_map = {
          dest_id   : user.id,
          dest_name : user.name,
          sender_id : 'id_04',
          msg_text  : 'Hi there ' + user.name + '!  Wilma here.'
        }
        callback_map.updatechat([person_map])
      
      return

    setTimeout( do_updatechat, 8000)
    return



  # Try once per second to use listchange callback.
  # Stop trying after first success.
  send_listchange =  () -> 
    listchange_idto = setTimeout(  () ->
      if callback_map.listchange 
        callback_map.listchange([ peopleList ])
        emit_mock_msg()
        listchange_idto = undefined
      else
        send_listchange()
      return

    , 1000 
    )

    return


  # We have to start the process ...
  send_listchange()

  return { 
    emit : emit_sio, 
    on : on_sio 
  }


#--------------- END mockSio -----------------


@spa = {} if not @spa?
@spa.fake = {
  mockSio
}