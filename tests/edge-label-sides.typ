// Test: edge label on all four sides (north, south, east, west)
// and with label-pos as a bare ratio (defaults to "north" side).
#import "@preview/cetz:0.4.2"
#import "/lib/nodes.typ": node, edge

#set page(width: 10cm, height: 10cm, margin: 5pt)

#cetz.canvas({
  node((-3,  3), [A], name: "a", stroke: black)
  node(( 3,  3), [B], name: "b", stroke: black)
  node((-3, -3), [C], name: "c", stroke: black)
  node(( 3, -3), [D], name: "d", stroke: black)

  // horizontal edge — label north (above line)
  edge("a.east", "b.west",
    label: [north], label-pos: (50%, "north"),
    mark: (end: ">"))

  // horizontal edge — label south (below line)
  edge("c.east", "d.west",
    label: [south], label-pos: (50%, "south"),
    stroke: blue, mark: (end: ">"))

  // vertical edge — label east (right of line)
  edge("b.south", "d.north",
    label: [east], label-pos: (50%, "east"),
    stroke: red, mark: (end: ">"))

  // vertical edge — label west (left of line)
  edge("a.south", "c.north",
    label: [west], label-pos: (50%, "west"),
    stroke: green, mark: (end: ">"))

  // bare ratio label-pos (no side tuple) — defaults to "north"
  edge("a", "d",
    label: [bare 30%], label-pos: 30%,
    stroke: orange, mark: (end: ">"))
})
