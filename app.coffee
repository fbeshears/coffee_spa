#app.coffee -  express server chapter 7 of SPA book


# ------------ BEGIN MODULE SCOPE VARIABLES --------------

http    = require 'http'    
express = require 'express' 

routes  = require './lib/routes'

app     = express()

server  = http.createServer( app )
# ------------- END MODULE SCOPE VARIABLES ---------------

# ------------- BEGIN SERVER CONFIGURATION ---------------

# using book instructions on p. 241 logger doesn't work with separate 
# configure for development
# don't use: SET NODE_ENV=development coffee app.coffee
# see below for what does work with logger

# in windows start server in production mode with
# SET NODE_ENV=production
# coffee app.coffee

 


app.configure () ->
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.static( "#{__dirname}/public" ) 
  app.use app.router 
  return

app.configure 'development',  () ->
  app.use express.logger() 
  app.use express.errorHandler {
    dumpExceptions : true,
    showStack      : true
  }

  return

app.configure 'production',  () ->
  app.use express.errorHandler() 
  return

routes.configRoutes app, server

# -------------- END SERVER CONFIGURATION ----------------

# ----------------- BEGIN START SERVER -------------------
server.listen( 3000 )
console.log(
  'Express server listening on port %d in %s mode',
   server.address().port, app.settings.env
)
# ------------------ END START SERVER --------------------
