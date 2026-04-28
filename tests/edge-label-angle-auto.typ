// Test: edge label with label-angle:auto follows the selected segment direction
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, edge, node

#set page(width: 12cm, height: 11cm, margin: 5pt)

#let lbl(body) = box(inset: .1cm, stroke: black, body)

#canvas({
  node((-4, 3), [A], name: "a", stroke: black)
  node((0, 1), [B], name: "b", stroke: black)
  node((4, 4), [C], name: "c", stroke: black)
  node((-4, -1), [D], name: "d", stroke: black)
  node((0, -3), [E], name: "e", stroke: black)
  node((4, -5), [F], name: "f", stroke: black)
  node((4, 1), [G], name: "g", stroke: black)

  edge("a.east", "b.west", label: lbl[auto diag], label-pos: (60%, -.2), label-angle: auto, mark: (end: ">"))

  edge(
    (-4.5, .5),
    (-.5, -1.5),
    label: lbl[tight .01],
    label-pos: (50%, .01),
    label-angle: auto,
    stroke: purple,
  )

  edge(
    "b.north",
    "c.west",
    routing: "2w-south",
    label: lbl[auto seg1],
    label-pos: (1, 50%, .2),
    label-angle: auto,
    stroke: blue,
    mark: (end: ">"),
  )

  edge(
    "d.east",
    "e.west",
    routing: "3w-east",
    bend: .8,
    label: lbl[auto seg2],
    label-pos: (2, 60%, .2),
    label-angle: auto,
    stroke: red,
    mark: (end: ">"),
  )

  edge(
    "f.west",
    "e.east",
    label: lbl[auto flat],
    label-pos: (40%, .2),
    label-angle: auto,
    stroke: green,
    mark: (end: ">"),
  )

  edge(
    "g.west",
    "e.east",
    label: lbl[auto flat],
    label-pos: (40%, .2),
    label-angle: auto,
    stroke: green,
    mark: (end: ">"),
  )
})
