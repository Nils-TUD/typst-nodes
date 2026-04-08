// Test: edge label with label-angle and label-inset
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": edge, node

#set page(width: 10cm, height: 8cm, margin: 5pt)

#let lbl(lbl, ..args) = box(inset: .2cm, stroke: black, lbl)

#cetz.canvas({
  node((-3, 2), [A], name: "a", stroke: black)
  node((3, 2), [B], name: "b", stroke: black)
  node((-3, -2), [C], name: "c", stroke: black)
  node((3, -2), [D], name: "d", stroke: black)

  // label-angle: 45deg
  edge("a.east", "b.west", label: lbl[45°], label-angle: 45deg, mark: (end: ">"))

  // label-angle: 90deg (vertical label)
  edge("c.east", "d.west", label: lbl[90°], label-angle: 90deg, stroke: blue, mark: (end: ">"))

  // label-inset: large inset creates a bigger box around the label
  edge("a.south", "c.north", label: lbl[inset], label-pos: (50%, "east"), label-inset: .5cm, stroke: red, mark: (
    end: ">",
  ))

  // label-inset: zero — label sits flush against the line
  edge("b.south", "d.north", label: lbl[0 inset], label-pos: (30%, "west"), label-inset: 0pt, stroke: green, mark: (
    end: ">",
  ))
})
