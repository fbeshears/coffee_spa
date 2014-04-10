###
spa.data.coffee

###
 
# global $, io, spa 

stateMap = { sio : null }



makeSio =  () ->
  socket = io.connect( '/chat' );

  do_emit = ( event_name, data ) ->
    socket.emit( event_name, data )
    return

  do_on =  ( event_name, callback ) ->
    socket.on event_name, () ->
      callback( arguments )
      return

    return


  return {
    emit : do_emit,
    on   : do_on
  }


getSio =  () ->
  stateMap.sio = makeSio() if not stateMap.sio 
  return stateMap.sio;


initModule =  () ->
  return



@spa = {} if not @spa?

@spa.data = {
  getSio
  initModule
}

