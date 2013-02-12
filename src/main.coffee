# This contains the main code for the client, which sets up and connects all
# the necessary pieces.

state = new State()
machine = new Machine()
display = new Display(state, machine)
input = new Input(state, machine)

setInterval(
  ->
    machine.update()
    display.draw()
  50
)
