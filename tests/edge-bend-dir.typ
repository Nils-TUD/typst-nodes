// Test: 3-segment routing with explicit bend modes.
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, edge, node

#set page(width: 12cm, height: 10cm, margin: 5pt)

#canvas({
  node((-4, 3), [A], name: "a", stroke: black)
  node((1, 0), [B], name: "b", stroke: black)
  node((-4, -3), [C], name: "c", stroke: black)
  node((-5, -1), [E], name: "e", stroke: black)
  node((0, 3), [F], name: "f", stroke: black)
  node((5, 1), [G], name: "g", stroke: black)
  node((0, -4), [H], name: "h", stroke: black)
  node((4, -1), [I], name: "i", stroke: black)

  edge("a.south", "b.north", routing: "3w-south", bend: "same-dir", mark: (end: ">"))
  edge("c.north", "b.south", routing: "3w-north", bend: "same-dir", stroke: blue, mark: (end: ">"))
  edge("e.east", "f.west", routing: "3w-east", bend: "same-dir", stroke: red, mark: (end: ">"))
  edge("g.west", "h.east", routing: "3w-west", bend: "same-dir", stroke: green, mark: (end: ">"))
  edge("c.south", "h.south", routing: "3w-south", bend: "opposite-dir", stroke: purple, mark: (end: ">"))
  edge("i.south", "g.south", routing: "3w-south", bend: "opposite-dir", stroke: orange, mark: (end: ">"))
})
