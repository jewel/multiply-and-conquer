# This is a state machine that will run a simulation on each of the connected
# machines, including the server.  The simulation will run at the same speed on
# all machines.
#
# Don't use rand() directly in here.  Instead, pre-generate an array of random
# floats and keep reusing it.
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
    @dests = []
    @selected = false

class @Machine
  constructor: ->
    @units = []
    @impassable = []
    @height = 400
    @width = 400

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
      cmp(a.stuck, b.stuck)

    for unit in @units
      unit.moved = false

    for unit in @units
      continue if unit.moved
      dest = unit.dests[0]
      unless dest
        unit.stuck -= 15
        unit.stuck = 0 if unit.stuck < 0
        continue

      shove = 1
      shove = dest.shove if dest.shove?

      if dest.wait?
        if dest.wait < 0
          delete dest.wait
        else
          dest.wait--
          continue

      # Try to move closer to our destination
      # We will move diagonally directly toward it if we can
      x = cmp( dest.x, unit.x )
      y = cmp( dest.y, unit.y )
      if x == 0 and y == 0 or dest.tries? and dest.tries < 0
        unit.dests.shift()
        continue

      continue if @try_move unit, x, y, shove
      unit.stuck += 20
      # next we will try to move horizontally or vertical towards it.
      # Finally, we should try and move diagonally perpendicular to our goal
      if Math.abs( unit.x - dest.x ) > Math.abs( unit.y - dest.y )
        continue if @try_move unit, x, 0
        continue if @try_move unit, x, 1
        continue if @try_move unit, x, -1
        continue if @try_move unit, 0, y
      else
        continue if @try_move unit, 0, y
        continue if @try_move unit, 1, y
        continue if @try_move unit, -1, y
        continue if @try_move unit, x, 0

      # Try going a new direction temporarily
      # if unit.stuck > 100
      #   continue if @try_move unit,  1,  1
      #   continue if @try_move unit,  0,  1
      #   continue if @try_move unit, -1,  1
      #   continue if @try_move unit,  1,  0
      #   continue if @try_move unit, -1,  0
      #   continue if @try_move unit,  1, -1
      #   continue if @try_move unit,  0, -1
      #   continue if @try_move unit, -1, -1

      dest.tries-- if dest.tries?
      unit.stuck = 300 if unit.stuck > 300

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

  try_move: (unit, x, y, shove=0) ->
    return false if x == 0 and y == 0
    dest_x = unit.x + x
    dest_y = unit.y + y
    return false unless @valid(dest_x, dest_y)
    other = @get(dest_x, dest_y)
    return false if other == true
    if other
      return false unless shove
      return false if other.moved
      return false unless unit.stuck > 150
      # unit in our way has a destination, try switching orders
      if other.dests.length == 0
        # make sure unit gets back to where it goes
        other.dests.push
          x: other.x
          y: other.y
          wait: 2
      else
        other.dests[0].wait = 1

      temp = other.dests
      other.dests = unit.dests
      unit.dests = temp
      # also switch selection state
      temp = other.selected
      other.selected = unit.selected
      unit.selected = temp
      unit.moved = true
      other.moved = true
      other.stuck -= 1

      # other.stuck = unit.stuck = Math.max( other.stuck, unit.stuck )
      return true
    @move unit, dest_x, dest_y
    unit.moved = true
    unit.stuck -= 15
    unit.stuck = 0 if unit.stuck < 0
    true

  move: (unit, x, y) ->
    if @get(x, y)
      throw "Can't move to #{x}, #{y}.  There is already someone there."
    @set unit.x, unit.y, null
    @set x, y, unit
    unit.x = x
    unit.y = y
