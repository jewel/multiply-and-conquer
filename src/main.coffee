# This contains the main code for the client, which sets up and connects all
# the necessary pieces.

state = new State()
machine = new Machine()
display = new Display(state, machine)
client = new Client(state, machine)
input = new Input(state, machine, client)

client.connect()

draw_times = []
setInterval(
  ->
    machine.update()
    unless machine.server_tick - machine.tick > 5
      start = new Date().getTime()
      display.draw()
      end = new Date().getTime()
      mspf = end - start
      draw_times.push mspf
      if draw_times.length > 40
        draw_times.shift()

    if machine.tick % 40 == 0
      sum = 0
      for i in draw_times
        sum += i
      console.log Math.round(sum / draw_times.length)

  50
)
