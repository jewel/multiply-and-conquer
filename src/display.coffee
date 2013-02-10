class Display
  constructor: ->
    @canvas = document.getElementById( 'field' )
    @ctx = canvas.getContext('2d')

  draw: ->

