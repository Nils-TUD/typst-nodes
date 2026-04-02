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

#let gap = .5

#let block(pos, lbl, ..args) = node(
  pos,
  text(size: .8em)[#lbl],
  inset: .4cm,
  radius: 2pt,
  ..args
)

#let serv(pos, lbl, ..args) = block(
  pos, lbl,
  fill: colors.at(2),
  width: 3.8cm,
  height: gap * 2,
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

#cetz.canvas({
  block((0, 0), [Hardware], fill: colors.at(4), width: 8cm, name: "hw")
  block(
    (north-of: ("hw", gap)),
    [Microkernel],
    fill: colors.at(1),
    width: 8cm,
    name: "kernel"
  )
  serv((north-of: ("kernel", gap * 3, "left")),  [Network], name: "net")
  serv((north-of: ("kernel", gap * 3, "right")), [Driver],  name: "drv")

  for (node, side, shift, no) in (
    ("net", "west", -.5, [1]),
    ("drv", "east",  .5, [2]),
    ("drv", "west", -.5, [3]),
    ("net", "east",  .5, [4]),
  ) {
    let reverse = side == "east"
    edge(
      node + ".south",
      "kernel.north",
      label: box-no(no),
      label-pos: (50%, side),
      routing: "vertical",
      shift: shift,
      mark: if reverse { (start: ">") } else { (end: ">") },
      stroke: 3pt,
    )
  }
})
