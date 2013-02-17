class @Display
  constructor: (state, machine) ->
    @canvas = document.getElementById( 'map' )
    @ctx = @canvas.getContext('2d')
    @state = state
    @machine = machine

  draw: ->
    if @canvas.height != @machine.height or @canvas.width != @machine.width
      @canvas.height = @machine.height
      @canvas.width = @machine.width

    @ctx.save()
    @ctx.fillStyle = '#444'
    @ctx.fillRect 0, 0, @machine.width, @machine.height
    @ctx.restore()


    @image = @ctx.getImageData 0, 0, @machine.width, @machine.height

    for pos in @machine.impassable
      @set pos.x, pos.y, 0, 0, 0

    @dests = []
    @dests[@machine.width*@machine.height] = false
    for unit in @machine.units
      continue unless unit.team == @state.team
      local = @state.local(unit)

      for dest in unit.dests
        if local.selected
          i = Math.floor local.intensity * 128
        else
          i = Math.floor local.intensity * 32 + 128 - 16
        @set dest.x, dest.y, i, i, i
        @dests[dest.y*@machine.width + dest.x] = true

    @drawn = []
    @drawn[@machine.width*@machine.height] = false
    for unit in @machine.units when unit.team == @state.team
      @show_location unit.x, unit.y

    @ctx.putImageData @image, 0, 0

    @draw_selection()
    @draw_orders()

  show_location: (sx, sy) ->
    for dy in [-10...10]
      y = sy + dy
      for dx in [-10...10]
        x = sx + dx
        index = y * @machine.width + x
        continue if @drawn[index]
        @drawn[index] = true
        unit = @machine.get x, y
        if unit == true
        else if !unit
          @set x, y, 127, 127+16, 127 unless @dests[index]
        else
          @draw_unit unit

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
