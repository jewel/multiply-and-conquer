class @MapRect
  constructor: (x, y, w, h) ->
    @x = x
    @y = y
    @w = w
    @h = h

  # normalize coordinates to x, y, w, h
  @from_coords: (a, b) ->
    x = Math.min a[0], b[0]
    y = Math.min a[1], b[1]
    x2 = Math.max a[0], b[0]
    y2 = Math.max a[1], b[1]
    w = x2 - x + 1
    h = y2 - y + 1
    new MapRect(x, y, w, h)

  inside: (x, y) ->
    x >= @x and x <= @x + @w and y >= @y and y <= @y + @h
