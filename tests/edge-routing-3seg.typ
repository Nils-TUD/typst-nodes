// Test: edges with 3-segment routing (south, north, east, west)
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": edge, node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#cetz.canvas({
  node((-3, 3), [A], width: 2cm, height: 2cm, name: "a", stroke: black)
  node((3, 3), [B], width: 2cm, height: 2cm, name: "b", stroke: black)
  node((-3, -1), [C], width: 2cm, height: 2cm, name: "c", stroke: black)
  node((3, -1), [D], width: 2cm, height: 2cm, name: "d", stroke: black)

  edge("a.south", "b.south", routing: "south", bend: .5, mark: (end: ">"))
  edge("c.north", "d.north", routing: "north", bend: .5, mark: (end: ">"), stroke: blue)
  edge("a.east", "c.east", routing: "east", bend: .8, mark: (end: ">"), stroke: red)
  edge("b.west", "d.west", routing: "west", bend: .8, mark: (end: ">"), stroke: green)
})
