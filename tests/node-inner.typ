// Test: child nodes placed inside a parent with inner positioning
// (in-north, in-south, in-east, in-west, in-north-west, etc.)
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, node

#set page(width: 7cm, height: 7cm, margin: 5pt)

#canvas({
  // Large parent container
  node((0, 0), [], name: "p", width: 5cm, height: 5cm, stroke: black)

  // Children pinned to inner edges
  node((in-north: ("p", .1cm)), [N], name: "n", fill: silver, width: 1.2cm, height: .6cm)
  node((in-south: ("p", .1cm)), [S], name: "s", fill: silver, width: 1.2cm, height: .6cm)
  node((in-west: ("p", .1cm)), [W], name: "w", fill: silver, width: .6cm, height: 1.2cm)
  node((in-east: ("p", .1cm)), [E], name: "e", fill: silver, width: .6cm, height: 1.2cm)
  node((in-north-west: ("p", .1cm)), [NW], name: "nw", fill: luma(200), width: 1cm, height: .6cm)
  node((in-north-east: ("p", .1cm)), [NE], name: "ne", fill: luma(200), width: 1cm, height: .6cm)
  node((in-south-west: ("p", .1cm)), [SW], name: "sw", fill: luma(200), width: 1cm, height: .6cm)
  node((in-south-east: ("p", .1cm)), [SE], name: "se", fill: luma(200), width: 1cm, height: .6cm)
  node((in-center: "p"), [C], name: "c", fill: luma(180), width: 30%, height: .6cm)
})
