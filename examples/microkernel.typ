#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": node, edge

#set page(width: 10cm, height: 7cm)
#set text(font: "Noto Sans", size: 1.5em)

#let colors = (
  rgb("#4A90E2"),
  rgb("#E94E77"),
  rgb("#F5A623"),
  rgb("#FFFFFF"),
  rgb("#BBBBBB"),
).map(c => c.lighten(50%))

#let big-gap = .5
#let gap = .3

#let block(pos, lbl, ..args) = node(
  pos,
  text(size: .8em)[#lbl],
  inset: .4cm,
  radius: 2pt,
  ..args
)

#let app(pos, lbl, ..args) = block(
  pos,
  lbl,
  fill: colors.at(0),
  width: 4cm,
  height: 1.1cm,
  ..args,
)

#let serv(pos, lbl, ..args) = block(
  pos,
  lbl,
  fill: colors.at(2),
  width: 4cm,
  height: 1.5cm,
  ..args,
)

#let box-no(no) = box(
  radius: 50%,
  inset: .25em,
  width: .6cm,
  height: .6cm,
  stroke: 1pt,
  fill: white,
  text(size: .8em)[#no],
)

#let call(..args) = edge(stroke: 3pt, mark: (end: ">"), ..args)

#cetz.canvas({
  import cetz.draw: line, circle, content

  block((0, 0), [Hardware], fill: colors.at(4), width: 8cm, name: "hw")
  block(
    (north-of: ("hw", big-gap)),
    [Microkernel],
    fill: colors.at(1),
    width: 8cm,
    name: "kernel"
  )

  serv(
    (north-of: ("kernel", big-gap * 3, "right")),
    [Driver],
    width: 3.8cm,
    height: big-gap * 2,
    name: "drv",
  )
  serv(
    (north-of: ("kernel", big-gap * 3, "left")),
    [Network],
    width: 3.8cm,
    height: big-gap * 2,
    name: "app",
  )

  call(
    "app.south",
    "kernel.north",
    label: box-no([1]),
    label-pos: (50%, "west"),
    routing: "vertical",
    shift: -.5,
  )
  call(
    "drv.south",
    "kernel.north",
    label: box-no([2]),
    label-pos: (50%, "east"),
    routing: "vertical",
    shift: .5,
    mark: (start: ">"),
  )
  call(
    "drv.south",
    "kernel.north",
    label: box-no([3]),
    label-pos: (50%, "west"),
    routing: "vertical",
    shift: -.5,
  )
  call(
    "app.south",
    "kernel.north",
    label: box-no([4]),
    label-pos: (50%, "east"),
    routing: "vertical",
    shift: .5,
    mark: (start: ">"),
  )
})
