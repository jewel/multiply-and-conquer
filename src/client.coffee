class @Client
  constructor: (state, machine) ->
    @socket = null
    @last_received = null
    @state = state
    @machine = machine
    @on_resync = ->

  connect: ->
    @socket = io.connect window.location.href
    @update_timeout 10000

    @socket.on 'connect', =>
      @update_timeout 5000

    @socket.on 'team', (msg) =>
      @state.team = msg

    @socket.on 'machine', (msg) =>
      @machine.deserialize msg

    @socket.on 'resync', (msg) =>
      @on_resync(msg)

    @socket.on 'orders', (msg) =>
      @machine.new_orders msg

    @socket.on 'disconnect', ->

    @socket.on 'error', (err) ->

    @socket.on 'tick', (msg) =>
      @machine.server_tick = msg.tick
      @machine.server_hash[msg.tick] = msg.hash

  send_orders: (unit, orders) ->
    @socket.emit 'orders'
      id: unit.id
      orders: orders

  resync: ->
    @socket.emit 'resync'

  # Private

  update_timeout: (offset) ->
    @last_received = new Date().getTime() + offset
