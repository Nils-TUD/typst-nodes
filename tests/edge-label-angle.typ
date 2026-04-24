// Test: edge label with label-angle and label-pos distance
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, edge, node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#let lbl(lbl, ..args) = box(inset: .1cm, stroke: black, lbl)

#canvas({
  node((-3, 2), [A], name: "a", stroke: black)
  node((3, 2), [B], name: "b", stroke: black)
  node((-3, -2), [C], name: "c", stroke: black)
  node((3, -2), [D], name: "d", stroke: black)

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
})
