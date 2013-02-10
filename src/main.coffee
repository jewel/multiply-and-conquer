# This contains the main code for the client, which sets up and connects all
# the necessary pieces.

machine = new Machine()
display = new Display(machine)
input = new Input(machine)

setInterval(
  ->
    machine.update()
    display.draw()
  30
)
