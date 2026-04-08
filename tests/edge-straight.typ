// Test: straight edges (no routing) between nodes
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": edge, node

#set page(width: 8cm, height: 4cm, margin: 5pt)

#cetz.canvas({
  node((-2.5, 0), [A], name: "a", stroke: black)
  node((2.5, 0), [B], name: "b", stroke: black)
  node((0, -2), [C], name: "c", stroke: black, fill: silver)

  edge("a.east", "b.west", mark: (end: ">"))
  edge("a.south", "c.north", mark: (end: ">"), stroke: blue)
  edge("b.south", "c.north", mark: (end: ">"), stroke: red)
})
