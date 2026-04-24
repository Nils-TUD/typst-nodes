// Test: 3-segment routing with explicit bend value
//
// By default bend is auto (half the span). Here we test an explicit bend
// value both smaller and larger than the default.
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, edge, node

#set page(width: 10cm, height: 11cm, margin: 5pt)

#canvas({
  node((-3, 3.5), [A1], name: "a1", stroke: black)
  node((3, 3.5), [B1], name: "b1", stroke: black)
  node((-3, 1.5), [A2], name: "a2", stroke: black)
  node((3, 1.5), [B2], name: "b2", stroke: black)

  edge("a1.north", "b1.north", routing: "3w-north", bend: 1cm, mark: (end: ">"))
  edge("a2.south", "b2.south", routing: "3w-south", stroke: blue, mark: (end: ">"))

  node((-2, 1), [A3], name: "a3", stroke: black)
  node((2, 1), [B3], name: "b3", stroke: black)
  node((-2, 4), [C2], name: "c2", stroke: black)
  node((2, 4), [D2], name: "d2", stroke: black)

  edge("a3.south", "b3.south", routing: "3w-south", bend: 3cm, stroke: red, mark: (end: ">"))
  edge("a2.west", "a1.west", routing: "3w-west", mark: (start: ">"))
  edge("b1.east", "b2.east", routing: "3w-east", mark: (end: ">"))
  edge("d2.west", "b3.west", routing: "3w-west", bend: 1cm, stroke: blue, mark: (end: ">"))
  edge("c2.east", "a3.east", routing: "3w-east", bend: 2cm, stroke: red, mark: (end: ">"))
})
