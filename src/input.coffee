class @Input
  constructor: (state, machine, client) ->
    @canvas = document.getElementById('map')
    @state = state
    @machine = machine
    @drag_time = null
    @drag_position = null
    @dragging = null
    @last_group = 0
    @client = client

    @canvas.oncontextmenu = -> false

    document.onmousedown = (e) =>
      @drag_start = new Date().getTime()
      @drag_position = @get_mouse_coords(e)
      if e.button == 0
        @left_mouse_down(e)
        false
      else if e.button == 2
        @right_mouse_down(e)
        false
      else
        true

    document.onmouseup = (e) =>
      # considered dragging if it's been longer 
      now = new Date().getTime()
      interval = now - @drag_start
      pos = @get_mouse_coords(e)
      prev = @drag_position
      movement = Math.abs(pos[0] - prev[0]) + Math.abs(pos[1] - prev[1])

      @dragging = interval > 200 or movement > 5

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
    @

  left_mouse_up: (e) ->
    @state.selection.end = @get_mouse_coords(e)

    if @dragging
      rect = MapRect.from_coords @state.selection.start, @state.selection.end

      for unit in @machine.units when unit.team is @state.team
        @state.local(unit).selected = rect.inside unit.x, unit.y
    else
      pos = @get_mouse_coords e
      clicked = @machine.get(pos[0], pos[1])
      clicked ||= @machine.get(pos[0]+1, pos[1])
      clicked ||= @machine.get(pos[0], pos[1]+1)
      clicked ||= @machine.get(pos[0]-1, pos[1])
      clicked ||= @machine.get(pos[0], pos[1]-1)
      clicked = null if clicked and clicked.team != @state.team
      clicked = @state.local(clicked) if clicked
      for unit in @machine.units when unit.team is @state.team
        local = @state.local(unit)
        local.selected = clicked and clicked.group == local.group

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
    new_group = ++@last_group
    for unit in @machine.units when unit.team is @state.team
      local = @state.local(unit)
      if local.selected
        local.group = new_group
        selected.push unit

    assigned = {}
    get = (x,y) =>
      if assigned["#{x},#{y}"]
        return true
      unit = @machine.get(x, y)
      return false unless unit
      if unit == true
        return true
      return true unless unit.team is @state.team
      local = @state.local(unit)
      return false if local.group == new_group
      if unit.dests.length == 0
        return true

    set = (x,y) ->
      assigned["#{x},#{y}"] = true

    search_space = [
      [ 1, 0 ],
      [ -1, 0 ],
      [ 0, 1 ],
      [ 0, -1 ],
    ]
    queue = orders
    marked = {}
    while queue.length > 0 and selected.length > 0
      pos = queue.shift()
      unless get(pos[0], pos[1])
        unit = selected.shift()
        set pos[0], pos[1]

        @client.send_orders unit, [
          x: pos[0]
          y: pos[1]
        ]

      for offset in search_space
        new_pos = [pos[0] + offset[0], pos[1] + offset[1]]
        id = "#{new_pos[0]},#{new_pos[1]}"
        unless marked[id]
          marked[id] = true
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
