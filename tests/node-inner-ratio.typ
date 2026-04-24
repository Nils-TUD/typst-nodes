// Test: inner placement with ratio width/height
//
// When width or height is given as a ratio (e.g. 80%), it is resolved relative
// to the container's measured size.
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, node

#set page(width: 8cm, height: 8cm, margin: 5pt)

#canvas({
  // Large parent
  node((0, 0), [], name: "p", width: 5cm, height: 5cm, stroke: black)

  // Child that fills 80% of the container width, fixed height
  node((in-north: ("p", .2cm)), [80% wide], name: "r-w", stroke: black, fill: silver, width: 80%, height: .6cm)

  // Child that fills 80% of the container height, fixed width
  node(
    (in-west: ("p", .2cm)),
    [60% tall],
    name: "r-h",
    stroke: black,
    fill: luma(210),
    width: .8cm,
    height: 60%,
    body-angle: 90deg,
  )

  // Child that fills 50% width and 50% height (centered in south-east corner)
  node((in-south-east: ("p", .2cm)), [50%×50%], name: "r-wh", stroke: black, fill: luma(230), width: 50%, height: 50%)
})
