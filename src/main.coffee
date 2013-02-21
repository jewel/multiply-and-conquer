# This contains the main code for the client, which sets up and connects all
# the necessary pieces.

@state = state = new State()
@machine = machine = new Machine()
display = new Display(state, machine)
client = new Client(state, machine)
input = new Input(state, machine, client)

client.connect()

times =
  machine: []
  display: []

mainloop = ->
  time = (name, func) ->
    start = new Date().getTime()
    func()
    end = new Date().getTime()
    mspf = end - start
    dest = times[name]
    dest.push mspf
    if dest.length > 40
      dest.shift()

  time 'machine', ->
    machine.update()

  if machine.server_tick - machine.tick < 2
    time 'display', ->
      display.draw()

  if machine.tick % 40 == 0
    msg = ""
    total = 0
    for name, values of times
      sum = 0
      for val in values
        sum += val
      avg = Math.round(sum / values.length)
      total += avg
      msg += "#{name}: #{avg}  "

    console.log "#{msg}  total: #{total}"

timer_id = setInterval mainloop, 50

resyncing = false

client.on_resync = (msg) ->
  while msg.tick > machine.tick
    machine.update()
  other = new Machine()
  other.deserialize msg
  machine.compare_with other
  machine.deserialize(msg)
  timer_id = setInterval mainloop, 50
  resyncing = false

machine.on 'resync', ->
  return if resyncing
  resyncing = true
  clearInterval timer_id
  client.resync()
