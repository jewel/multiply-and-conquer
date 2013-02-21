impassable = []
units = []

p = console.log

process.stdin.resume()
process.stdin.setEncoding('ascii')

data = ''
process.stdin.on 'data', (chunk) ->
  data += chunk

process.stdin.on 'end', ->
  lines = data.split(/\n/)
  index = 0
  format = lines[index++]
  note = lines[index++]
  dims = lines[index++].split(/\ /)
  width = parseInt(dims[0], 10)
  height = parseInt(dims[1], 10)
  depth = lines[index++]

  x = 0
  y = 0
  while index < lines.length
    r = parseInt(lines[index++], 10)
    g = parseInt(lines[index++], 10)
    b = parseInt(lines[index++], 10)

    if !r and !g and !b
      impassable.push
        x: x
        y: y
    else if r and g and b
      # white, do nothing
    else
      units.push
        x: x
        y: y
        health: Math.floor(Math.random() * 80) + 20
        team: if r then 1 else if b then 2 else 0

    x++
    if x >= width
      y++
      x = 0

  output = JSON.stringify
    width: width
    height: height
    units: units
    impassable: impassable

  process.stdout.write output
