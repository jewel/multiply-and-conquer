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
    @state.orders = []
    @state.orders.push @get_mouse_coords(e)

  right_mouse_up: (e) ->
    @state.orders.push @get_mouse_coords(e)

    prev = null
    orders = []

    # draw a solid line along the path using bresenham's algorithm
    draw_line = (x0, y0, x1, y1) ->
      dx = Math.abs x1 - x0
      dy = Math.abs y1 - y0
      sx = if x0 < x1 then 1 else -1
      sy = if y0 < y1 then 1 else -1
      err = dx - dy
      length = Math.max dx, dy

      while length-- > 0
        orders.push [x0, y0]
        if err * 2 > -dy
          err -= dy
          x0 += sx
        if err * 2 < dx
          err += dx
          y0 += sy

    for order in @state.orders
      if prev
        draw_line prev[0], prev[1], order[0], order[1]
      prev = order

    orders = [@get_mouse_coords(e)] if orders.length == 0

    selected = []
    for unit in @machine.units
      if unit.selected
        unit.dests = []
        selected.push unit

    assigned = {}
    get = (x,y) ->
      return assigned["#{x},#{y}"]

    set = (x,y) ->
      assigned["#{x},#{y}"] = true

    search_space = [
      [ 1, 0 ],
      [ -1, 0 ],
      [ 0, 1 ],
      [ 0, -1 ],
    ]
    queue = orders
    searched = {}
    while queue.length > 0 and selected.length > 0
      pos = queue.shift()
      unless get(pos[0], pos[1])
        unit = selected.shift()
        set pos[0], pos[1]
        unit.dests.push { x: pos[0], y: pos[1] }

      for offset in search_space
        new_pos = [pos[0] + offset[0], pos[1] + offset[1]]
        id = "#{new_pos[0]},#{new_pos[1]}"
        unless searched[id]
          searched[id] = true
          queue.push new_pos

    @state.orders = []

  right_mouse_move: (e) ->
    pos = @get_mouse_coords(e)
    if @state.orders.length > 0
      prev = @state.orders[ @state.orders.length - 1]
      return if pos[0] == prev[0] and pos[1] == prev[1]

    @state.orders.push pos

  get_mouse_coords: (e) ->
    [
      e.clientX + window.scrollX - @canvas.offsetLeft
      e.clientY + window.scrollY - @canvas.offsetTop
    ]
