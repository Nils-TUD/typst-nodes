// Test: edges with 2-segment routing (2w-north, 2w-south, 2w-east, 2w-west)
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, edge, node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#canvas({
  node((-3, 3), [A], width: 2cm, height: 2cm, name: "a")
  node((3, 1), [B], width: 2cm, height: 2cm, name: "b")
  node((-3, -2), [C], width: 2cm, height: 2cm, name: "c")
  node((3, -3), [D], width: 2cm, height: 2cm, name: "d")

  edge("a.south", "b.west", routing: "2w-south", mark: (end: ">"))
  edge("a.east", "b.north", routing: "2w-east", shift: (.4cm, -.2cm), mark: (end: ">"), stroke: blue)
  edge("b.west", "c.north", routing: "2w-west", shift: -.4cm, mark: (end: ">"), stroke: red)
  edge(
    "d.north",
    "c.east",
    routing: "2w-north",
    shift: (.3cm, .4cm),
    label: [2w],
    label-pos: -0.3,
    mark: (end: ">"),
    stroke: green,
  )
})
