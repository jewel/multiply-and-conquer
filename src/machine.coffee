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

class Unit
  constructor: (x, y) ->
    @x = x
    @y = y
    @team = 0
    @stuck = 0
    @health = 100
    @dests = []

class Machine
  constructor: ->
    @wipe()

  wipe: ->
    @server_tick = 0
    @units = []
    @units_by_id = {}
    @impassable = []
    @height = 400
    @width = 400
    @tick = 0
    @pending_orders = []
    @last_id = 0

    @map = []

  generate: ->
    for x in [20..70]
      for y in [20..70]
        unit = new Unit(x, y)
        unit.id = ++@last_id
        unit.team = 1
        unit.health = Math.floor(Math.random()*20) + 80
        @units.push unit

    for x in [80..130]
      for y in [80..130]
        unit = new Unit(x, y)
        unit.id = ++@last_id
        unit.team = 2
        unit.health = Math.floor(Math.random()*20) + 80
        @units.push unit

    for unit in @units
      @units_by_id[unit.id] = unit
      @set unit.x, unit.y, unit

    for i in [0..170]
      @impassable.push { x: i, y: Math.round(Math.cos(i/100)*100 + 200) }
      @impassable.push { x: i, y: Math.round(Math.cos(i/100)*100 + 200)+1 }

    for i in [240..399]
      @impassable.push { x: i, y: Math.round(Math.cos(i/100)*100 + 200) }
      @impassable.push { x: i, y: Math.round(Math.cos(i/100)*100 + 200)+1 }

    for i in @impassable
      @set i.x, i.y, true

  new_orders: (msg) ->
    @pending_orders.push msg

  update: ->
    return if @tick >= @server_tick
    @tick++

    while @pending_orders.length > 0
      break if @pending_orders[0].tick > @tick
      first = @pending_orders.shift()
      unit = @units_by_id[first.id]
      continue unless unit # might have died already
      unit.dests = first.orders

    cmp = (a, b) ->
      if a < b then -1 else if a > b then 1 else 0

    prioritized_units = @units.sort (a, b) ->
      cmp(a.stuck, b.stuck)

    for unit in @units
      unit.moved = false

    for unit in prioritized_units
      continue if unit.moved

      # TODO check if adjacent is on our team
      adjacent_unit = @get unit.x+1, unit.y+1
      adjacent_unit ||= @get unit.x+1, unit.y-1
      adjacent_unit ||= @get unit.x-1, unit.y-1
      adjacent_unit ||= @get unit.x-1, unit.y+1

      if adjacent_unit and adjacent_unit.team != unit.team
        adjacent_unit.health -= 4
        unit.moved = true
        continue

      dest = unit.dests[0]
      unless dest
        unit.stuck -= 15
        unit.stuck = 0 if unit.stuck < 0
        continue

      shove = 1

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

      dest.tries-- if dest.tries?
      unit.stuck = 1024 if unit.stuck > 1024

    copy = @units
    @units = []
    for unit in copy
      if unit.health <= 0
        delete @units_by_id[unit.id]
        @set unit.x, unit.y, null
        continue
      @units.push unit

  serialize: ->
    units: @units
    impassable: @impassable
    tick: @tick

  deserialize: (msg) ->
    @wipe()
    @tick = msg.tick

    for u in msg.units
      unit = new Unit()
      for k, v of u
        unit[k] = v
      @units.push unit
      @units_by_id[unit.id] = unit
      @set unit.x, unit.y, unit

    for i in msg.impassable
      @impassable.push i
      @set i.x, i.y, true

  get: (x, y) ->
    return true unless @valid
    @map[y*@width+x]

  # private

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
      return false if other.team != unit.team
      return false if other.moved
      return false unless unit.stuck > 150
      # unit in our way has a destination, switch places
      if other.dests.length == 0
        # make sure unit gets back to where it goes
        other.dests.push
          x: other.x
          y: other.y
          wait: 2
      else
        other.dests[0].wait ||= 1

      swap = (prop) ->
        temp = other[prop]
        other[prop] = unit[prop]
        unit[prop] = temp

      swap 'x'
      swap 'y'
      swap 'stuck'
      @set unit.x, unit.y, unit
      @set other.x, other.y, other
      unit.moved = other.moved = true
      other.stuck -= 1
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

root = exports ? this
root.Machine = Machine
