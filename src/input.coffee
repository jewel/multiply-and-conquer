class Input
  constructor: (state) ->
    @keys_pressed = {}
    @mouse_pressed = false
    @mouse_pos = null

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
      false

    document.onmousemove = (e) =>
      @mouse_pos = e

  get_input: ->
