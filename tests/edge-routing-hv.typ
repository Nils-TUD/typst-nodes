// Test: edges with horizontal/vertical routing and shift
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": edge, node

#set page(width: 8cm, height: 8cm, margin: 5pt)

#cetz.canvas({
  node((-2.5, 1.5), [A], name: "a", width: 2cm, height: 2cm, stroke: black)
  node((2.5, 0), [B], name: "b", width: 2cm, height: 2cm, stroke: black)
  node((-1, -2), [C], name: "c", width: 2cm, height: 2cm, stroke: black, fill: silver)
  node((1, 2.5), [D], name: "d", width: 2cm, height: 2cm, stroke: black, fill: silver)

  edge("a.north-east", "d.west", routing: "horizontal", mark: (end: ">"))
  edge("a.north-east", "d.west", routing: "horizontal", shift: -.3cm, stroke: blue, mark: (end: ">"))
  edge("b.north-west", "a.east", routing: "horizontal", mark: (start: ">"))

  edge("c.north-west", "a.south", routing: "vertical", mark: (end: ">"), stroke: red)
  edge("c.north-west", "a.south", routing: "vertical", shift: .3cm, stroke: green, mark: (end: ">"))
})
