# This is a state machine that will run a simulation on each of the connected
# machines, including the server.  The simulation will run at the same speed on
# all machines.
#
# Don't use Math.random() directly in here.  Instead, use @rand(), which is
# deterministically random.
#
# Since we aren't very sensitive to lag in a RTS, we don't ever do anything
# that hasn't been approved by the server first.  That saves us from needing to
# backtrack.  We will adjust the speed of the simulation so that it stays a
# little bit behind our worst ping time in the last five seconds.

class Unit
  constructor: (x, y) ->
    @x = x
    @y = y
    @id = 0
    @team = 0
    @stuck = 0
    @health = 100
    @sapping = 0
    @power = 0
    @dests = []

  hash: ->
    h = @x + @y + @team + @stuck + @health + @sapping + @power + @dests.length
    for dest in @dests
      h += dest.x + dest.y
      h += dest.wait if dest.wait?
      h += 1 if dest.auto?
      h += dest.tries if dest.tries?
    h

  compare_with: (other) ->
    check = (prop) =>
      return if @[prop] == other[prop]
      console.log "unit #{@id} #{prop}: #{other[prop]} != #{@[prop]}"

    check 'x'
    check 'y'
    check 'team'
    check 'stuck'
    check 'health'
    check 'sapping'
    check 'power'

    if other.dests.length != @dests.length
      console.log "unit #{@id} dests: #{other.dests.length} != #{@dests.length}"

    us = JSON.stringify(@dests)
    them = JSON.stringify(other.dests)
    console.log "unit #{@id} dests: #{them} != #{us}" unless them == us

class Machine
  constructor: ->
    @callbacks =
      team_switch: []
      resync: []
    @wipe()

  wipe: ->
    @server_tick = 0
    @server_hash = {}
    @units = []
    @units_by_id = {}
    @impassable = []
    @height = 400
    @width = 400
    @tick = 0
    @pending_orders = []
    @last_id = 0
    @generate_random()

    @map = []

  on: (event, func) ->
    @callbacks[event].push func

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
      cmp(a.stuck, b.stuck) || cmp(a.id, b.id)

    for unit in @units
      unit.moved = false

    for unit in prioritized_units
      continue if unit.moved
      continue if unit.team == 0

      if unit.sapping
        other = @units_by_id[unit.sapping]
        if !other
          unit.sapping = 0
          unit.power = 20
          unit.moved = true
          continue

        if unit.dests.length == 0 or !unit.dests[0].auto?
          unit.dests.unshift
            x: other.x
            y: other.y
            auto: true

        if other.team != 0
          unit.sapping = 0
          unit.power = 20
          continue
        else
          other.power--
          if other.power <= 0
            other.power = 0
            other.team = unit.team
            for cb in @callbacks.team_switch
              cb(other, unit)

      if !unit.sapping
        other = @find_adjacent unit.x, unit.y, (other) ->
          other.team != unit.team and other.team != 0

        if other
          if unit.dests.length == 0 or !unit.dests[0].auto?
            unit.dests.unshift
              x: other.x
              y: other.y
              auto: true
            if unit.dests.length == 1
              unit.dests.push
                x: unit.x
                y: unit.y
                auto: true

          other.health -= 4
          unit.moved = true
          unit.power = 10
          continue

        other = @find_adjacent unit.x, unit.y, (other) ->
          other.team == 0

        other ||= @find_adjacent unit.x, unit.y, (other) ->
          other.team == unit.team and other.sapping > 0

        if other
          if other.team == 0
            unit.sapping = other.id
          else
            sappee = @units_by_id[other.sapping]
            unit.sapping = other.sapping if sappee and sappee.team == 0

          unit.moved = true
          continue

        if unit.power > 0
          unit.power--
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
      if unit.stuck > 1024
        unit.stuck = 1024

        if not unit.sapping
          unit.stuck = 0
          unit.dests.unshift
            x: unit.x + @rand(-30, 30)
            y: unit.y + @rand(-30, 30)
            tries: 40
            auto: true

    copy = @units
    @units = []
    for unit in copy
      if unit.health <= 0
        delete @units_by_id[unit.id]
        @set unit.x, unit.y, null
        continue
      @units.push unit

    if @server_hash[@tick]
      server_hash = @server_hash[@tick]
      delete @server_hash[@tick]
      our_hash = @hash()
      unless server_hash == our_hash
        for cb in @callbacks.resync
          console.log "Out of sync: #{server_hash} vs #{our_hash}"
          cb()

  hash: ->
    val = @tick + @random_pos + @width + @height + @last_id
    for unit in @units
      val += unit.hash()
      val %= 2000000000
    val

  compare_with: (other) ->
    check = (prop) =>
      return if @[prop] == other[prop]
      console.log "#{prop}: #{other[prop]} != #{@[prop]}"

    check 'tick'
    check 'random_pos'
    check 'width'
    check 'height'
    check 'last_id'

    for i in [0..(@random_numbers.length)]
      ours = @random_numbers[i]
      theirs = other.random_numbers[i]
      continue if ours == theirs
      console.log "rand #{i}: #{ours} != #{theirs}"

    for other_unit in other.units
      unit = @units_by_id[other_unit.id]
      unless unit
        console.log "unit #{other_unit.id} missing"
        continue
      unit.compare_with other_unit

  generate_random: ->
    @random_numbers = []
    @random_pos = 0
    for i in [0...512]
      @random_numbers.push Math.round(Math.random() * 1000000000)

  rand: (min, max) ->
    unless max?
      max = min
      min = 0
    @random_pos++
    num = @random_numbers[@random_pos % @random_numbers.length]
    num % (max-min) + min

  serialize: ->
    random_numbers: @random_numbers
    random_pos: @random_pos
    units: @units
    impassable: @impassable
    tick: @tick
    width: @width
    height: @height

  deserialize: (msg) ->
    @wipe()
    @tick = msg.tick || 0
    if msg.random_numbers?
      @random_numbers = msg.random_numbers
    else
      @generate_random()
    @random_pos = msg.random_pos || 0
    @width = msg.width
    @height = msg.height

    for u in msg.units
      unit = new Unit()
      for k, v of u
        unit[k] = v
      unit.id ||= ++@last_id
      unit.power = 1000 if unit.team == 0 and !u.power?
      @units.push unit
      @units_by_id[unit.id] = unit
      @set unit.x, unit.y, unit

    @last_id = @units.length

    for i in msg.impassable
      @impassable.push i
      @set i.x, i.y, true

  offsets: [
    [ 0, 1 ]
    [ 0, -1 ]
    [ 1, 0 ]
    [ -1, 0 ]
    [ 1, 1 ]
    [ -1, -1 ]
    [ 1, -1 ]
    [ -1, 1 ]
  ]

  find_adjacent: (x, y, where) ->
    for offset in @offsets
      unit = @get(x+offset[0], y+offset[1])
      continue unless unit
      continue if unit == true
      continue unless where(unit)
      return unit

    return null

  get: (x, y) ->
    return true unless @valid x, y
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
      return false if other.power > 0
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
