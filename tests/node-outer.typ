// Test: nodes placed with outer directional positioning
// (east-of, west-of, north-of, south-of, and diagonal corners)
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, node

#set page(width: 8cm, height: 8cm, margin: 5pt)

#canvas({
  node((0, 0), [Center], name: "c", stroke: black)

  node((east-of: ("c", .4cm)), [E], name: "e", stroke: black, fill: silver)
  node((west-of: ("c", .4cm)), [W], name: "w", stroke: black, fill: silver)
  node((north-of: ("c", .4cm)), [N], name: "n", stroke: black, fill: silver)
  node((south-of: ("c", .4cm)), [S], name: "s", stroke: black, fill: silver)

  node((north-east-of: ("c", .4cm)), [NE], name: "ne", stroke: black, fill: luma(200))
  node((north-west-of: ("c", .4cm)), [NW], name: "nw", stroke: black, fill: luma(200))
  node((south-east-of: ("c", .4cm)), [SE], name: "se", stroke: black, fill: luma(200))
  node((south-west-of: ("c", .4cm)), [SW], name: "sw", stroke: black, fill: luma(200))
})
