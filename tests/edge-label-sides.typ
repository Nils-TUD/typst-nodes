// Test: edge label placement using label-pos (segment, position, distance)
// Demonstrates positive/negative dist on horizontal and vertical segments.
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, edge, node

#set page(width: 12cm, height: 10cm, margin: 5pt)

#canvas({
  node((-3, 3), [A], name: "a", stroke: black)
  node((3, 3), [B], name: "b", stroke: black)
  node((-3, -3), [C], name: "c", stroke: black)
  node((3, -3), [D], name: "d", stroke: black)

  // Horizontal edge: positive dist → north of line
  edge("a.east", "b.west", label: [north +0.3], label-pos: 0.3, mark: (end: ">"))

  // Horizontal edge: negative dist → south of line
  edge("c.east", "d.west", label: [south -0.3], label-pos: -0.3, mark: (end: ">"), stroke: blue)

  // Horizontal edge: dist=0 → center of box on line
  edge("a", "d", label: [center 0], label-pos: 0, mark: (end: ">"), stroke: orange)

  // Horizontal edge: position at 25%, dist=0.3
  edge("c", "b", label: [25% +0.3], label-pos: (25%, 0.3), mark: (end: ">"), stroke: purple)

  // Vertical edge: positive dist → east (right) of line
  edge("a.south", "c.north", label: [east +0.3], label-pos: 0.3, mark: (end: ">"), stroke: red)

  // Vertical edge: negative dist → west (left) of line
  edge("b.south", "d.north", label: [west -0.3], label-pos: -0.3, mark: (end: ">"), stroke: green)
})
