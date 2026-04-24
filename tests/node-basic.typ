// Test: basic node at an absolute coordinate
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, node

#set page(width: 6cm, height: 4cm, margin: 5pt)

#canvas({
  node((0, 0), [Hello], name: "a", stroke: black)
  node((3, 0), [World], name: "b", stroke: black, fill: silver)
})
