// Test: edge label with label-angle and label-pos distance
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, edge, node

#set page(width: 10cm, height: 12cm, margin: 5pt)

#let lbl(lbl, ..args) = box(inset: .1cm, stroke: black, lbl)

#canvas({
  node((-3, 3), [A], name: "a", stroke: black)
  node((3, 3), [B], name: "b", stroke: black)
  node((-3, 0), [C], name: "c", stroke: black)
  node((3, 0), [D], name: "d", stroke: black)
  node((-3, -6), [E], name: "e", stroke: black)
  node((3, -6), [F], name: "f", stroke: black)

  // label-angle: 45deg
  edge("a.east", "b.west", label: lbl[45°], label-angle: 45deg, mark: (end: ">"))

  // label-angle: 90deg (vertical label)
  edge("c.east", "d.west", label: lbl[90°], label-angle: 90deg, stroke: blue, mark: (end: ">"))

  // label-pos: small distance using the label's own box bounds
  edge("a.south", "c.north", label: lbl[dist .2], label-pos: .2, stroke: red, mark: (
    end: ">",
  ))

  // label-pos: larger distance on a vertical edge
  edge("b.south", "d.north", label: lbl[dist .3], label-pos: (30%, .3), stroke: green, mark: (
    end: ">",
  ))

  edge(
    "c.south",
    "e.north",
    label: lbl[diag 90°],
    label-pos: (55%, -0.1),
    label-angle: 90deg,
    stroke: purple,
    mark: (end: ">"),
  )

  edge(
    "d.south",
    "f.north",
    label: lbl[diag 90°],
    label-pos: (45%, 0.1),
    label-angle: 270deg,
    stroke: blue,
    mark: (end: ">"),
  )

  edge(
    "d.south",
    "e.north",
    label: lbl[diag -45°],
    label-pos: (50%, 0),
    label-angle: -45deg,
    stroke: orange,
    mark: (end: ">"),
  )
})
