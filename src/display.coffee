class @Display
  constructor: (state, machine) ->
    @canvas = document.getElementById( 'map' )
    @ctx = @canvas.getContext('2d')
    @state = state
    @machine = machine
    @width = 400
    @height = 400

  draw: ->
    @ctx.save()
    @ctx.fillStyle = '#fff'
    @ctx.fillRect 0, 0, @width, @height
    @ctx.restore()

    @image = @ctx.getImageData 0, 0, @width, @height
    for unit in @machine.units when unit.selected
      for dest in unit.dests
        i = Math.floor(unit.intensity * 127)
        @set dest.x, dest.y, i, i, i

    for unit in @machine.units
      r = unit.stuck
      g = 0
      b = Math.floor(unit.intensity * 255)
      if unit.selected
        g = b
        b = 0
      @set unit.x, unit.y, r, g, b

    for pos in @machine.impassable
      @set pos.x, pos.y, 255, 0, 0

    @ctx.putImageData @image, 0, 0

    @draw_selection()
    @draw_orders()

  draw_orders: ->
    return unless @state.orders.length > 1
    @ctx.save()
    @ctx.strokeStyle = 'rgba(0,80,0,0.5)'

    first = @state.orders
    @ctx.beginPath()
    @ctx.moveTo first[0], first[1]
    for order in @state.orders[1..]
      @ctx.lineTo order[0], order[1]

    @ctx.stroke()
    @ctx.restore()

  draw_selection: ->
    return unless @state.selection.start and @state.selection.end

    rect = MapRect.from_coords @state.selection.start, @state.selection.end

    @ctx.save()
    @ctx.strokeStyle = '#000'
    @ctx.strokeRect( rect.x + 1, rect.y + 1, rect.w, rect.h )

    @ctx.strokeStyle = '#0f0'
    @ctx.strokeRect( rect.x, rect.y, rect.w, rect.h )
    @ctx.restore()

  set: (x, y, r, g, b) ->
    data = @image.data
    index = (x + y * @width) * 4
    data[index + 0] = r
    data[index + 1] = g
    data[index + 2] = b
