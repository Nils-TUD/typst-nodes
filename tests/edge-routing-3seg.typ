// Test: edges with 3-segment routing (3w-south, 3w-north, 3w-east, 3w-west)
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": edge, node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#cetz.canvas({
  node((-3, 3), [A], width: 2cm, height: 2cm, name: "a", stroke: black)
  node((3, 3), [B], width: 2cm, height: 2cm, name: "b", stroke: black)
  node((-3, -1), [C], width: 2cm, height: 2cm, name: "c", stroke: black)
  node((3, -1), [D], width: 2cm, height: 2cm, name: "d", stroke: black)

  edge("a.south", "b.south", routing: "3w-south", bend: .5, mark: (end: ">"))
  edge("c.north", "d.north", routing: "3w-north", bend: .5, mark: (end: ">"), stroke: blue)
  edge("a.east", "c.east", routing: "3w-east", bend: .8, mark: (end: ">"), stroke: red)
  edge("b.west", "d.west", routing: "3w-west", bend: .8, mark: (end: ">"), stroke: green)
})
