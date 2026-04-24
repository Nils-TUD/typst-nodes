// Test: edges with labels (label, label-pos, label-angle)
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, edge, node

#set page(width: 12cm, height: 8cm, margin: 5pt)

#canvas({
  node((-3, 2), [A], name: "a", stroke: black)
  node((3, 2), [B], name: "b", stroke: black)
  node((-3, -2), [C], name: "c", stroke: black)
  node((3, -2), [D], name: "d", stroke: black)

  // Default label-pos: seg=1, pos=50%, dist=0.3 (north of line)
  edge("a.east", "b.west", label: [default], mark: (end: ">"))

  // Label at 25%, south of line (negative dist)
  edge("c.east", "d.west", label: [25% south], label-pos: (25%, -0.3), mark: (end: ">"), stroke: blue)

  // Vertical edge: positive dist → east (right of line)
  edge("a.south", "c.north", label: [east], label-pos: 0.3, mark: (end: ">"), stroke: red)

  // 3w-east routing: default segment=2 (vertical middle), positive dist → east
  edge(
    "b.east",
    "d.east",
    routing: "3w-east",
    bend: "opposite-dir",
    label: [routed],
    mark: (end: ">"),
    stroke: green,
  )
})
