// Test: outer placement with varying dist values
//
// Verifies that dist correctly controls the gap between the reference node's
// edge and the new node's edge, for all four cardinal directions.
// Also tests dist=0 (touching edges).
#import "@preview/cetz:0.4.2"
#import "/lib/nodes.typ": node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#cetz.canvas({
  node((0, 0), [Ref], name: "ref", width: 1.5cm, height: .7cm, stroke: black)

  // dist = 0: new node touches the reference edge
  node((north-of: ("ref", 0)),     [0],   name: "n0", fill: silver, width: .9cm, height: .5cm)
  node((south-of: ("ref", 0)),     [0],   name: "s0", fill: silver, width: .9cm, height: .5cm)
  node((east-of:  ("ref", 0)),     [0],   name: "e0", fill: silver, width: .5cm, height: .5cm)
  node((west-of:  ("ref", 0)),     [0],   name: "w0", fill: silver, width: .5cm, height: .5cm)

  // dist = 0.5cm
  node((north-of: ("ref", .5cm)),  [.5],  name: "n5", fill: luma(210), width: .9cm, height: .5cm)
  node((south-of: ("ref", .5cm)),  [.5],  name: "s5", fill: luma(210), width: .9cm, height: .5cm)
  node((east-of:  ("ref", .5cm)),  [.5],  name: "e5", fill: luma(210), width: .5cm, height: .5cm)
  node((west-of:  ("ref", .5cm)),  [.5],  name: "w5", fill: luma(210), width: .5cm, height: .5cm)

  // dist = 1cm
  node((north-of: ("ref", 1cm)),   [1],   name: "n1", fill: white, width: .9cm, height: .5cm)
  node((south-of: ("ref", 1cm)),   [1],   name: "s1", fill: white, width: .9cm, height: .5cm)
  node((east-of:  ("ref", 1cm)),   [1],   name: "e1", fill: white, width: .5cm, height: .5cm)
  node((west-of:  ("ref", 1cm)),   [1],   name: "w1", fill: white, width: .5cm, height: .5cm)
})
