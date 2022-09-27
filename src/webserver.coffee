express     = require 'express'
bodyParser  = require('body-parser')
uuid        = require 'uuid'
app         = express()

bunyan      = require 'bunyan'
webLog      = bunyan.createLogger name: 'webserver'
authenticationHandler = require('./auth') process.env.AUTH_MECHANISM

module.exports =

  start: (port, sessionFactory) ->

    webCtx = (req, res, acceptcb) ->
      accept = ->
      reject = ->
        res.statusCode = 403
        res.setHeader('WWW-Authenticate', 'Basic realm="Node"')
        res.end('Invalid authorization data provided. Please check username and pwd')
      name = 'base64'
      password = 'missing'
      if `req.headers.authorization == undefined`
        reject = ->
          res.statusCode = 401
          res.setHeader('WWW-Authenticate', 'Basic realm="Node"')
          res.end('Please provide WWW-Authorization using basic in headers with base 64 encoding')
      else
        encoded = req.headers.authorization.split(' ')[1]
        decoded = new Buffer(encoded, 'base64').toString()
        name = decoded.split(':')[0]
        password = decoded.split(':')[1]
        accept = acceptcb
      method: 'password', username: name, password: password, accept: accept, reject: reject

    app.use (req, res, next) ->
      sessf = sessionFactory.instance()
      authenticationHandler(sessf) webCtx req, res, next

    app.use express.static 'src/public'
    app.use bodyParser.urlencoded extended: false
    
    eventHandlers = []
    addEventHandler = (connectionId, event, cb) ->
      eventHandlers[connectionId] = {} unless eventHandlers[connectionId]
      eventHandlers[connectionId][event] = cb

    webSession = (res, connectionId) -> ->
      channel = ->
        write: (data) ->
          res.write "event: data\n"
          res.write "data: #{JSON.stringify data}\n\n"
        on: (event, cb) ->
          addEventHandler connectionId, "channel:#{event}", cb
        end: ->
          webLog.info 'Websession end', connectionId: connectionId
          delete eventHandlers[connectionId]
          res.end()

      once: (cmd, cb) ->
      on: (event, cb) ->
        switch event
          when 'shell' then cb channel
          else addEventHandler connectionId, "session:#{event}", cb


    app.get '/api/v1/terminal/stream/', (req, res) ->
      sessf = sessionFactory.instance()
      cba = ->
        terminalId = uuid.v4()
        webLog.info 'New terminal session', terminalId: terminalId
        res.setHeader 'Connection', 'Transfer-Encoding'
        res.setHeader 'Content-Type', 'text/event-stream; charset=utf-8'
        res.setHeader 'Transfer-Encoding', 'chunked'
        res.write 'event: connectionId\n'
        res.write "data: #{terminalId}\n\n"
        sessf.myhandler() webSession res, terminalId
        res.on 'close', ->
          eventHandlers[terminalId]['channel:end']()
      authenticationHandler(sessf) webCtx req, res, cba


    app.post '/api/v1/terminal/send/:terminalId', (req, res) ->
      terminalId = req.params.terminalId
      data = req.body.data
      if eventHandlers[terminalId]['channel:data']
        eventHandlers[terminalId]['channel:data'] data
      else
        webLog.error 'No input handler for connection', connectionId: connectionId
      res.end()

    app.post '/api/v1/terminal/resize-window/:terminalId', (req, res) ->
      terminalId = req.params.terminalId
      info =
        rows: parseInt req.body.rows
        cols: parseInt req.body.cols
      eventHandlers[terminalId]['session:window-change'] null, null, info
      res.json info
      res.end()

    server = app.listen port, ->
      host = server.address().address
      port = server.address().port
      webLog.info {host: host, port: port}, 'Listening'
