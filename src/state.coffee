# This contains the client-side game state.  This is information necessary to
# display correctly or interpret user input, but isn't synchronized over the
# network, nor does it contain the state of individual units (who are all
# tracked by StateMachine).
class @State
  constructor: ->
    @selection = {
      start: null,
      end: null
    }
    @orders = []
