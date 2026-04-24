// Test: label-pos distance semantics for 2w routing.
// The second segment is the default (seg 2).
//   2w-north/south: seg 2 is horizontal → positive dist = north, negative = south
//   2w-east/west:   seg 2 is vertical   → positive dist = east,  negative = west
// Both 2w-north and 2w-south with the same positive dist must place their
// labels on the same (north) side of the horizontal second segment.
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, edge, node

#set page(width: 12cm, height: 10cm, margin: 5pt)

#let lbl(text) = box(fill: white, stroke: black, inset: .3em, text)
#let tedge(..args) = edge(mark: (end: ">"), ..args)

#canvas({
  node((-4, 2), [A], width: 2cm, height: 2cm, name: "a")
  node((4, 0), [B], width: 2cm, height: 2cm, name: "b")
  node((-4, -2), [C], width: 2cm, height: 2cm, name: "c")
  node((2, -3), [D], width: 2cm, height: 2cm, name: "d")

  // north and south
  tedge("a.south", "b.west", routing: "2w-south", label: lbl[south +], label-pos: 0.001, shift: .5)
  tedge("c.south", "d.west", routing: "2w-south", label: lbl[south -], label-pos: -0.001, shift: (0, -.5), stroke: blue)
  tedge("b.north", "a.east", routing: "2w-north", label: lbl[north +], label-pos: 0.001, shift: .5, stroke: orange)

  // west and east
  tedge("a.east", "b.north", routing: "2w-east", label: lbl[east −], label-pos: (1, 50%, -0.001), stroke: purple)
  tedge(
    "b.west",
    "c.north",
    routing: "2w-west",
    label: lbl[west +],
    label-pos: (1, 50%, 0.001),
    shift: -.5,
    stroke: red,
  )

  // center
  tedge("b.south", "d.east", routing: "2w-south", label: lbl[south 0], label-pos: (1, 50%, 0), stroke: green)
})
