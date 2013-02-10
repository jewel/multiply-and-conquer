# This is a state machine that will run a simulation on each of the connected
# machines, including the server.  The simulation will run at the same speed on
# all machines.
#
# Be very careful about doing anything with rand() in here.
#
# Since we aren't very sensitive to lag in a RTS, we don't ever do anything
# that hasn't been approved by the server first.  That saves us from needing to
# backtrack.  We will adjust the speed of the simulation so that it stays a
# little bit behind our worst ping time in the last five seconds.

class @Unit
  constructor: (x, y) ->
    @x = x
    @y = y
    @intensity = Math.random()
    @stuck = 0

class @Machine
  constructor: ->
    @units = []
    @impassable = []
    @height = 400
    @width = 400
    @dest = {
      x: 300,
      y: 300
    }

    @map = []

    for x in [10..90]
      for y in [10..90]
        unit = new Unit(x, y)
        @units.push unit
        @set x, y, unit

    for i in [200..300] by 2
      @impassable.push { x: i, y: 200 }
      @impassable.push { x: 200, y: i }
      @impassable.push { x: i, y: 300 }
      @impassable.push { x: 300, y: i }

    for i in [0..200]
      @impassable.push { x: i, y: Math.round(Math.cos(i/100)*100 + 200) }

    for i in @impassable
      @set i.x, i.y, true

  update: ->
    cmp = (a, b) ->
      if a < b then -1 else if a > b then 1 else 0

    @units = @units.sort (a, b) ->
      cmp(b.stuck, a.stuck)

    for unit in @units
      # Try to move closer to our destination
      # We will move diagonally directly toward it if we can
      x = cmp( @dest.x, unit.x )
      y = cmp( @dest.y, unit.y )
      unit.stuck = 0 if unit.stuck < 0

      continue if @try_move unit, x, y
      # next we will try to move horizontally or vertical towards it.
      # Finally, we should try and move diagonally perpendicular to our goal
      if Math.abs( unit.x - @dest.x ) > Math.abs( unit.y - @dest.y )
        continue if @try_move unit, x, 0
        continue if @try_move unit, 0, y
        continue if @try_move unit, x, -y
      else
        continue if @try_move unit, 0, y
        continue if @try_move unit, x, 0
        continue if @try_move unit, -x, y

      # Can we move at all?
      continue if @try_move unit, 1, 1
      continue if @try_move unit, 1, 0
      continue if @try_move unit, 0, 1
      continue if @try_move unit, -1, -1
      continue if @try_move unit, -1, 0
      continue if @try_move unit, 0, -1
      continue if @try_move unit, 1, -1
      continue if @try_move unit, -1, 1

      unit.stuck += 5

  # private

  get: (x, y) ->
    @check_bounds x, y
    @map[y*@width+x]

  set: (x, y, val) ->
    @check_bounds x, y
    @map[y*@width+x] = val

  valid: (x, y) ->
    x >= 0 and y >= 0 and x < @width and y < @width

  check_bounds: (x, y) ->
    unless @valid x, y
      throw "Out of bounds (#{x}, #{y})"

  try_move: (unit, x, y) ->
    dest_x = unit.x + x
    dest_y = unit.y + y
    return false unless @valid(dest_x, dest_y)
    return false if @get(dest_x, dest_y)
    @move unit, dest_x, dest_y
    unit.stuck -= 10
    unit.stuck = 0 if unit.stuck < 0
    true

  move: (unit, x, y) ->
    if @get(x, y)
      throw "Can't move to #{x}, #{y}.  There is already someone there."
    @set unit.x, unit.y, null
    @set x, y, unit
    unit.x = x
    unit.y = y
