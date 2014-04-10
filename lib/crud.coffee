#crud.coffee



# ------------ BEGIN MODULE SCOPE VARIABLES --------------
mongodb     = require 'mongodb'
fsHandle    = require 'fs'    
path        = require 'path'
JSV         = require( 'JSV'     ).JSV


mongoServer = new mongodb.Server(
  'localhost', mongodb.Connection.DEFAULT_PORT
)

dbHandle    = new mongodb.Db(
  'spa',  mongoServer, { safe : true }
)

validator   = JSV.createEnvironment()

objTypeMap  = { 'user': {} }

# ------------- END MODULE SCOPE VARIABLES ---------------

# --------------- BEGIN UTILITY METHODS ------------------
loadSchema =  ( schema_name, schema_path ) ->
  fsHandle.readFile schema_path, 'utf8',  ( err, data ) ->
    objTypeMap[ schema_name ] = JSON.parse( data )
    return

  return

checkSchema =  ( obj_type, obj_map, callback ) ->
  schema_map = objTypeMap[ obj_type ]
  report_map = validator.validate( obj_map, schema_map )

  callback( report_map.errors )
  return

clearIsOnline =  () ->
  updateObj(
    'user',
    { is_online : true  },
    { is_online : false },
    ( response_map ) ->
      console.log( 'All users set to offline', response_map )
      return
  )
  return

# ---------------- END UTILITY METHODS -------------------


# ---------------- BEGIN PUBLIC METHODS ------------------
checkType    = ( obj_type ) ->
  if not objTypeMap[ obj_type ] 
    return { error_msg : "Object type #{obj_type} is not supported." }
  
  return null;

constructObj = ( obj_type, obj_map, callback ) ->
  type_check_map = checkType( obj_type )
  if ( type_check_map ) 
    callback( type_check_map )
    return

  inner = ( inner_error, result_map ) ->
      callback( result_map )
      return

  outer =  ( outer_error, collection ) ->
    options_map = { safe: true }
    collection.insert( obj_map, options_map, inner)
    return

  do_check = ( error_list ) ->
    if  error_list.length == 0 
      dbHandle.collection( obj_type, outer)
    else
      response.send {
        error_msg  : 'Input document not valid',
        error_list : error_list
      }
    return


  checkSchema( obj_type, obj_map, do_check)

  return

readObj  = ( obj_type, find_map, fields_map, callback ) ->
  type_check_map = checkType( obj_type )
  if ( type_check_map ) 
    callback( type_check_map )
    return

  inner = ( inner_error, map_list ) ->
    callback( map_list )
    return

  outer = ( outer_error, collection ) ->
    collection.find( find_map, fields_map ).toArray( inner )
    return

  dbHandle.collection( obj_type, outer)

  return
  

updateObj    = ( obj_type, find_map, set_map, callback ) ->
  type_check_map = checkType( obj_type )
  if ( type_check_map ) 
    callback( type_check_map )
    return

  inner =  ( inner_error, update_count ) ->
    callback { update_count : update_count }
    return

  outer = ( outer_error, collection ) ->
    collection.update( 
      find_map, 
      { $set : set_map },
      { safe : true, multi : true, upsert : false },
      inner 
    )
    return

  do_check = ( error_list ) ->
    if  error_list.length == 0 
      dbHandle.collection( obj_type, outer )
    else
      callback {
        error_msg  : 'Input document not valid',
        error_list : error_list
      }
    return

  checkSchema( obj_type, set_map, do_check )

  return

  
destroyObj   = ( obj_type, find_map, callback ) ->
  type_check_map = checkType( obj_type )
  if ( type_check_map ) 
    callback( type_check_map )
    return

  inner = ( inner_error, delete_count ) ->
    callback { delete_count: delete_count }
    return

  outer = ( outer_error, collection ) ->
    options_map = { safe: true, single: true }
    collection.remove(find_map, options_map, inner)
    return

  dbHandle.collection(obj_type, outer)

  return
  

module.exports = {
  makeMongoId : mongodb.ObjectID,
  checkType   : checkType,
  construct   : constructObj,
  read        : readObj,
  update      : updateObj,
  destroy     : destroyObj
}
# ----------------- END PUBLIC METHODS -----------------

# ------------- BEGIN MODULE INITIALIZATION --------------
dbHandle.open () ->
  console.log( '** Connected to MongoDB **' )
  clearIsOnline()
  return

# load schemas into memory (objTypeMap)
do () ->
  for own schema_name, schema_value of objTypeMap 
    schema_path = path.join(__dirname, "#{schema_name}.json")
    loadSchema( schema_name, schema_path )


# -------------- END MODULE INITIALIZATION ---------------