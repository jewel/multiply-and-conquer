class Client
  constructor: ->
    @socket = null
    @last_received = null

  connect: ->
    @socket = io.connect window.location.href
    @update_timeout 10000

    @socket.on 'connect', ->
      @update_timeout 5000

      state.start()

    @socket.on 'disconnect', ->

    @socket.on 'error', (err) ->

    @socket.on 'update', @recv_update

  # Private

  recv_update: (msg) =>

  update_timeout: (offset) ->
    @last_received = new Date().getTime() + offset
