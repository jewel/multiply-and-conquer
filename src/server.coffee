http = require 'http'
url = require 'url'
fs = require 'fs'
io = require 'socket.io'

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

io = io.listen(server)
io.set 'log level', 2

io.sockets.on 'connection', (client) ->
  client.on 'order', (msg) ->

  client.on 'error', ->
    console.log "error"

  client.on 'disconnect', ->
    console.log "disconnect"
