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
    @draw_destination()

  draw_destination: ->
    @ctx.save()
    @ctx.strokeStyle = 'rgba(0,0,0,0.05)'
    for unit in @machine.units
      continue unless unit.selected
      continue if unit.dests.length == 0
      dest = unit.dests[0]
      @ctx.beginPath()
      @ctx.moveTo(unit.x, unit.y)
      @ctx.lineTo(dest.x, dest.y)
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
