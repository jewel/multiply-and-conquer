class @Input
  constructor: (state, machine) ->
    @canvas = document.getElementById('map')
    @state = state
    @machine = machine

    @canvas.oncontextmenu = -> false

    document.onmousedown = (e) =>
      if e.button == 0
        @left_mouse_down(e)
        false
      else if e.button == 2
        @right_mouse_down(e)
        false
      else
        true

    document.onmouseup = (e) =>
      if e.button == 0
        @left_mouse_up(e)
        false
      else if e.button == 2
        @right_mouse_up(e)
        false
      else
        true

    document.onmousemove = (e) =>
      if e.button == 0
        @left_mouse_move(e)
        false
      else if e.button == 2
        @right_mouse_move(e)
        false
      else
        true

  # private
  left_mouse_down: (e) ->
    @state.selection.start = @get_mouse_coords(e)

  left_mouse_up: (e) ->
    @state.selection.end = @get_mouse_coords(e)

    rect = MapRect.from_coords @state.selection.start, @state.selection.end

    for unit in @machine.units
      unit.selected = rect.inside unit.x, unit.y

    @state.selection.start = null
    @state.selection.end = null

  left_mouse_move: (e) ->
    @state.selection.end = @get_mouse_coords(e)


  right_mouse_down: (e) ->

  right_mouse_up: (e) ->
    dest = @get_mouse_coords(e)

    selected = []
    for unit in @machine.units
      if unit.selected
        unit.dests = []
        selected.push unit

    row_size = Math.sqrt(selected.length)

    column = 0
    row = 0
    spacing = 1.5

    for unit in selected
      unit.dests.push
        x: Math.round(dest[0] - row_size/2*spacing + column * spacing)
        y: Math.round(dest[1] - row_size/2*spacing + row * spacing)
      column++
      if column > row_size
        row++
        column = 0

  right_mouse_move: (e) ->

  get_mouse_coords: (e) ->
    [
      e.clientX + window.scrollX - @canvas.offsetLeft
      e.clientY + window.scrollY - @canvas.offsetTop
    ]
