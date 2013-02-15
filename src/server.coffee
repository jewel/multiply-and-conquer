http = require 'http'
url = require 'url'
fs = require 'fs'
io = require 'socket.io'
{Machine} = require './machine'

send404 = (res) ->
  res.writeHead(404)
  res.write('404')
  res.end()
  res

server = http.createServer (req,res) ->
  path = url.parse(req.url).pathname
  console.log( path )
  path = '/index.html' if path == '/'
  fs.readFile "#{__dirname}/../public/" + path, (err,data) ->
    return send404 res if err
    ext = path.substr path.lastIndexOf( "." ) + 1
    content_type = switch ext
      when 'js' then 'text/javascript'
      when 'css' then 'text/css'
      when 'html' then 'text/html'
      else
        console.log "Unknown content type: #{ext}"
    res.writeHead 200
      'Content-Type': content_type
    res.write data, 'utf8'
    res.end()

server.listen 3000

console.log "Server running on http://localhost:3000"

machine = new Machine()
machine.generate()

update = ->
  machine.server_tick++
  machine.update()
  broadcast_all 'tick', machine.tick

  setTimeout update, 50

start_machine = ->
  update()

  # don't start again
  start_machine = ->

clients = {}

broadcast_all = (type, message) ->
  for id, client of clients
    client.emit type, message

io = io.listen(server)
io.set 'log level', 2

team = 0

io.sockets.on 'connection', (client) ->
  start_machine()
  clients[client.id] = client
  client.emit 'machine', machine.serialize()
  client.emit 'team', ((++team) % 2) + 1

  client.on 'orders', (msg) ->
    msg.tick = machine.tick + 1
    machine.new_orders msg
    broadcast_all 'orders', msg

  client.on 'error', ->
    console.log "error"

  client.on 'disconnect', ->
    console.log "disconnect"
    delete clients[client.id]
