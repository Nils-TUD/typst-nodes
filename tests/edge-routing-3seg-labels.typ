// Test: label-pos distance semantics for 3w routing.
// The middle segment (seg 2) is the default.
//   3w-north/south: seg 2 is horizontal → positive dist = north, negative = south
//   3w-east/west:   seg 2 is vertical   → positive dist = east,  negative = west
// Both 3w-north and 3w-south with the same positive dist must place their
// labels on the same (north) side of the horizontal middle segment.
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, edge, node

#set page(width: 10cm, height: 9cm, margin: 5pt)

#let lbl(text) = box(fill: white, stroke: black, inset: .3em, text)
#let tedge(..args) = edge(label-inset: 0pt, bend: .5, mark: (end: ">"), ..args)

#canvas({
  node((-3, 3), [A], width: 2cm, height: 2cm, name: "a", stroke: black)
  node((3, 3), [B], width: 2cm, height: 2cm, name: "b", stroke: black)
  node((-3, -2), [C], width: 2cm, height: 2cm, name: "c", stroke: black)
  node((3, -2), [D], width: 2cm, height: 2cm, name: "d", stroke: black)

  // north and south
  tedge("a.south", "b.south", routing: "3w-south", label: lbl[south +], label-pos: 0.001)
  tedge("c.north", "d.north", routing: "3w-north", label: lbl[north -], label-pos: -0.001, stroke: blue)
  tedge("a.north", "b.north", routing: "3w-north", label: lbl[north −], label-pos: (40%, -0.001), stroke: purple)

  // east and west
  tedge("a.east", "c.east", routing: "3w-east", label: lbl[east +], label-pos: (10%, 0.001), stroke: red)
  tedge("b.west", "d.west", routing: "3w-west", label: lbl[west −], label-pos: -0.001, stroke: green)

  // center placement
  tedge("c.south", "d.south", routing: "3w-south", label: lbl[center 0], label-pos: 0, stroke: eastern)

  // different edge
  tedge(
    "a.south",
    "d.north",
    routing: "3w-south",
    bend: 1,
    shift: (-.5, .5),
    label: lbl[seg1+],
    label-pos: (3, 50%, 0.001),
    stroke: maroon,
  )
})
