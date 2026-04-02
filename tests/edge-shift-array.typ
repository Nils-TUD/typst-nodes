// Test: 3-segment routing with shift as a (sa, sb) array
//
// shift can be a single value (same for both endpoints) or an array
// (shift-a, shift-b) to move each endpoint independently.
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": node, edge

#set page(width: 12cm, height: 9cm, margin: 5pt)

#cetz.canvas({
  node((-3.5,  2), [A], width: 2cm, height: 2cm, name: "a", stroke: black)
  node(( 3.5,  2), [B], width: 2cm, height: 2cm, name: "b", stroke: black)
  node((-3.5, -2), [C], width: 2cm, height: 2cm, name: "c", stroke: black)

  // symmetric scalar shift (reference, black)
  edge("a.north", "b.north", routing: "north", bend: 1cm,
    shift: 0, mark: (end: ">"))

  // shift as array: move A's attachment right, B's left
  edge("a.north", "b.north", routing: "north", bend: 2cm,
    shift: (.4cm, -.4cm), stroke: blue, mark: (end: ">"))

  // shift as array: move only one end
  edge("a.south", "b.south", routing: "south", bend: 1cm,
    shift: (.8cm, 0cm), stroke: red, mark: (end: ">"))

  // west routing with scalar shift
  edge("c.west", "a.west", routing: "west",
    shift: 0, mark: (end: ">"))

  // east routing with array shift
  edge("c.east", "a.east", routing: "east", bend: 2.5cm,
    shift: (.3cm, -.3cm), stroke: green, mark: (end: ">"))
})
