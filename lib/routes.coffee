#routes.coffee

# ------------ BEGIN MODULE SCOPE VARIABLES --------------

crud        = require './crud'
chat        = require './chat' 
makeMongoId = crud.makeMongoId

# ------------- END MODULE SCOPE VARIABLES ---------------


# ---------------- BEGIN PUBLIC METHODS ------------------

configRoutes = (app, server) ->

  app.get '/',  ( request, response ) ->
    response.redirect '/spa.html' 
    return

  app.all '/:obj_type/*?',  ( request, response, next ) ->
    response.contentType( 'json' )
    next()
    return

  app.get '/:obj_type/list',  ( request, response ) ->
    crud.read(
      request.params.obj_type, 
      {}, {}, 
      (map_list) ->  
        response.send( map_list )
        return
    )
    return

  app.post '/:obj_type/create',  ( request, response ) ->
    crud.construct(
      request.params.obj_type,
      request.body, 
      ( result_map ) -> 
        response.send( result_map )
        return
    )   
    return

  app.get '/:obj_type/read/:id', ( request, response ) ->
    crud.read(
      request.params.obj_type,
      { _id: makeMongoId( request.params.id ) },
      {},
      ( map_list ) ->
        response.send( map_list )
        return
    )
    return

  app.post '/:obj_type/update/:id', ( request, response ) ->
    crud.update(
      request.params.obj_type,
      { _id: makeMongoId( request.params.id ) },
      request.body,
      ( result_map ) ->
        response.send( result_map )
        return
    )
    return

  app.get '/:obj_type/delete/:id', ( request, response ) ->
    crud.destroy(
      request.params.obj_type,
      { _id: makeMongoId( request.params.id ) },
      ( result_map ) ->
        response.send( result_map )
        return
    )
    return

  chat.connect( server )

  return


module.exports = {
  configRoutes
}

# -- END PUBLIC METHODS



