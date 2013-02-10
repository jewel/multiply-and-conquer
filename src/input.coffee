class @Input
  constructor: (state) ->
    @keys_pressed = {}
    @mouse_pressed = false
    @mouse_pos = null
    @canvas = document.getElementById('map')
    @state = state

    window.onkeydown = (e) =>
      @keys_pressed[e.which] = true
      e.which != 32 && ( e.which < 37 || e.which > 40 )

    window.onkeyup = (e) =>
      @keys_pressed[e.which] = false
      e.which != 32 && ( e.which < 37 || e.which > 40 )

    window.onmousedown = (e) =>
      @mouse_pressed = true

      false

    window.onmouseup = (e) =>
      @mouse_pressed = false

      x = e.clientX + window.scrollX - @canvas.offsetLeft
      y = e.clientY + window.scrollY - @canvas.offsetTop
      @state.dest = { x: x, y: y }

      false

    #document.onmousemove = (e) =>
    #  @mouse_pos = e

  get_input: ->
