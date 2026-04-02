// Test: edges with labels (label, label-pos, label-dist, label-side, label-angle)
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": node, edge

#set page(width: 12cm, height: 8cm, margin: 5pt)

#cetz.canvas({
  node((-3,  2), [A], name: "a", stroke: black)
  node(( 3,  2), [B], name: "b", stroke: black)
  node((-3, -2), [C], name: "c", stroke: black)
  node(( 3, -2), [D], name: "d", stroke: black)

  // Default label position (50%, north side)
  edge("a.east", "b.west", label: [default], mark: (end: ">"))

  // Label at 25%, south side
  edge("c.east", "d.west",
    label: [25% south],
    label-pos: (25%, "south"),
    mark: (end: ">"),
    stroke: blue,
  )

  // Label with extra distance from line
  edge("a.south", "c.north",
    label: [dist],
    label-pos: (50%, "west"),
    label-dist: .3cm,
    mark: (end: ">"),
    stroke: red,
  )

  // Label with 3-segment routing on the middle segment
  edge("b.east", "d.east",
    routing: "east",
    label: [routed],
    label-pos: (50%, "east"),
    mark: (end: ">"),
    stroke: green,
  )
})
