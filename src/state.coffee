# This contains the client-side game state.  This is information necessary to
# display correctly or interpret user input, but isn't synchronized over the
# network, nor does it contain the state of individual units (who are all
# tracked by StateMachine).

class LocalUnitState
  constructor: ->
    @selected = false
    @group = 0
    @intensity = Math.random()

class @State
  constructor: (machine) ->
    @team = 1

    # mouse position
    @selection = {
      start: null,
      end: null
    }
    @orders = []

    # more details about local units, only relevant to Input
    @local_unit_state = []

  local: (unit) ->
    @local_unit_state[ unit.id ] ||= new LocalUnitState()
