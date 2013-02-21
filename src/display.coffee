class @Display
  constructor: (state, machine) ->
    @canvas = document.getElementById( 'map' )
    @ctx = @canvas.getContext('2d')
    @state = state
    @machine = machine
    @dest_changed = true
    @machine.on 'new_orders', =>
      @dest_changed = true

  draw: ->
    if Math.round(@canvas.height) != Math.round(@machine.height) or Math.round(@canvas.width) != Math.round(@machine.width)
      @canvas.height = @machine.height
      @canvas.width = @machine.width
      @image = null

    @first_draw()

    @draw_dests()

    @draw_units()

    @ctx.putImageData @image, 0, 0

    @draw_selection()
    @draw_orders()

  first_draw: ->
    return if @image
    @ctx.save()
    @ctx.fillStyle = '#444'
    @ctx.fillRect 0, 0, @machine.width, @machine.height
    @ctx.restore()

    @image = @ctx.getImageData 0, 0, @machine.width, @machine.height

  draw_dests: ->
    return unless @dest_changed
    @dest_changed = false
    @dests = new Uint8Array(@machine.width * @machine.height)
    for unit in @machine.units
      continue unless unit.team == @state.team
      local = @state.local(unit)

      for dest in unit.dests
        if local.selected
          i = Math.floor local.intensity * 128
        else
          i = Math.floor local.intensity * 32 + 64 - 16
        @set dest.x, dest.y, i, i, i
        @dests[dest.y*@machine.width + dest.x] = 1

  draw_units: ->
    drawn = new Uint8Array(@machine.width*@machine.height)

    queue = []

    for unit in @machine.units when unit.team == @state.team
      queue.push [unit.x, unit.y, 0]

    count = queue.length * 8 * 8

    while count-- > 0
      pos = queue.shift()
      index = pos[1] * @machine.width + pos[0]
      continue if drawn[index]
      drawn[index] = 1
      res = @draw_pos pos[0], pos[1], pos[2]
      continue unless res
      queue.push [pos[0] + 1, pos[1], pos[2]+1]
      queue.push [pos[0], pos[1] + 1, pos[2]+1]
      queue.push [pos[0] - 1, pos[1], pos[2]+1]
      queue.push [pos[0], pos[1] - 1, pos[2]+1]

  draw_pos: (x, y, mask) ->
    unit = @machine.get x, y
    if unit == true
      @set x, y, 0, 0, 0
      return false
    else if !unit
      index = y * @machine.width + x
      a = 127 - mask
      a = 68 if a < 68
      @set x, y, a, a, a unless @dests[index]
    else
      @draw_unit unit
    return true

  draw_unit: (unit) ->
    local = @state.local(unit)
    if unit.team == @state.team
      r = 0
      g = 0
      b = Math.floor(local.intensity * 127 + if unit.sapping then 0 else 127)
      if local.selected
        g = b
        b = 0
    else if unit.team == 0
      r = g = b = Math.floor(local.intensity * 64 + 191)
    else
      r = Math.floor(local.intensity * 127 + 128)
      g = 0
      b = 0

    @set unit.x, unit.y, r, g, b

  draw_orders: ->
    return unless @state.orders.length > 1
    @ctx.save()
    @ctx.strokeStyle = 'rgba(0,190,0,0.5)'

    first = @state.orders
    @ctx.beginPath()
    @ctx.moveTo first[0]+0.5, first[1]+0.5
    for order in @state.orders[1..]
      @ctx.lineTo order[0]+0.5, order[1]+0.5

    @ctx.stroke()
    @ctx.restore()

  draw_selection: ->
    return unless @state.selection.start and @state.selection.end

    rect = MapRect.from_coords @state.selection.start, @state.selection.end

    @ctx.save()
    @ctx.strokeStyle = '#000'
    @ctx.strokeRect( rect.x + 1.5, rect.y + 1.5, rect.w, rect.h )

    @ctx.strokeStyle = '#0f0'
    @ctx.strokeRect( rect.x + 0.5, rect.y + 0.5, rect.w, rect.h )
    @ctx.restore()

  set: (x, y, r, g, b) ->
    data = @image.data
    index = (x + y * @machine.width) * 4
    data[index + 0] = r
    data[index + 1] = g
    data[index + 2] = b
