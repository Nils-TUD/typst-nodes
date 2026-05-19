// Test: bezier edge labels with tangent-based auto angle and signed distance.
#import "@preview/cetz:0.5.2"
#import "/src/lib.typ": canvas, edge, node

#set page(width: 12cm, height: 10cm, margin: 5pt)

#let lbl(body) = box(inset: .1cm, stroke: black, body)

#canvas({
  node((-4, 3), [A], name: "a", stroke: black)
  node((2, 3), [B], name: "b", stroke: black)
  node((-4, -2), [C], name: "c", stroke: black)
  node((2, -2), [D], name: "d", stroke: black)

  cetz.draw.set-style(mark: (end: ">"))

  edge(
    "a.east",
    "b.west",
    routing: "bezier",
    label: lbl[auto],
    label-pos: (60%, .2),
    label-angle: auto,
  )

  edge(
    "c.east",
    "d.west",
    routing: "bezier",
    control: (-1, -4),
    label: lbl[manual],
    label-pos: (40%, -.2),
    label-angle: auto,
    stroke: blue,
  )

  edge(
    "a.south",
    "c.north",
    routing: "bezier",
    label: lbl[vertical],
    label-angle: auto,
    label-pos: (30%, -.4),
    stroke: orange,
  )

  edge(
    (-2.5, .5),
    (2.5, .5),
    routing: "bezier",
    control: (0, 2.5),
    label: lbl[fixed],
    label-pos: (50%, .15),
    label-angle: 0deg,
    stroke: red,
  )
})
