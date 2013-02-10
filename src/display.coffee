class @Display
  constructor: (state) ->
    @canvas = document.getElementById( 'map' )
    @ctx = @canvas.getContext('2d')
    @state = state
    @width = 400
    @height = 400

  draw: ->
    @ctx.save()
    @ctx.fillStyle = '#fff'
    @ctx.fillRect 0, 0, @width, @height
    @ctx.restore()

    @image = @ctx.getImageData 0, 0, @width, @height
    for unit in @state.units
      @set unit.x, unit.y, unit.stuck, 0, Math.floor(unit.intensity * 255)

    for pos in @state.impassable
      @set pos.x, pos.y, 255, 0, 0

    @ctx.putImageData @image, 0, 0

  # private
  set: (x, y, r, g, b) ->
    data = @image.data
    index = (x + y * @width) * 4
    data[index + 0] = r
    data[index + 1] = g
    data[index + 2] = b
