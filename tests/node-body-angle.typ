// Test: body-angle — rotated label inside node
//
// When body-angle != 0deg the code computes the AABB of the rotated rectangle
// to size the containing node correctly.  We test 45deg and 90deg.
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, node

#set page(width: 10cm, height: 6cm, margin: 5pt)

#canvas({
  // 0deg baseline
  node((-4, 0), [Baseline], name: "a0", stroke: black, fill: silver, body-angle: 0deg)

  // 45deg — AABB should be wider and taller than the unrotated box
  node((0, 0), [45 deg], name: "a45", stroke: black, fill: luma(210), body-angle: 45deg)

  // 90deg — effectively transposes width and height
  node((4, 0), [90 deg], name: "a90", stroke: black, fill: luma(190), body-angle: 90deg)

  // Explicit fixed size with rotation: the box is user-specified,
  // the body content is rotated inside it
  node((-2, -3), [fixed+rot], name: "af", stroke: black, fill: white, width: 2.5cm, height: 1cm, body-angle: 30deg)
})
