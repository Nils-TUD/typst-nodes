// Test: body-pos corner positions
//
// body-pos can be set to "north-west", "north-east", "south-west", or
// "south-east" to anchor the label at a corner of the node, offset inward
// diagonally by body-dist along both axes.
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, node

#set page(width: 10cm, height: 8cm, margin: 5pt)

// Place a node with a corner body-pos. Common dimensions and styling are fixed;
// only the position, label, name, and corner are varied per call.
#let corner-node(
  pos,
  label,
  name: none,
  corner: "north-west",
  dist: .15cm,
  fill: silver,
  stroke: black,
  width: 3cm,
  height: 1.5cm,
) = node(
  pos,
  label,
  name: name,
  stroke: stroke,
  fill: fill,
  width: width,
  height: height,
  body-pos: corner,
  body-dist: dist,
)

#let large-corner-node(pos, label, name, corner) = corner-node(
  pos,
  label,
  name: name,
  corner: corner,
  dist: .1cm,
  stroke: none,
  fill: none,
  width: 4cm,
  height: 2cm,
)

#canvas({
  // Four separate nodes, one per corner
  corner-node((-3, 2), [NW label], name: "bnw", corner: "north-west")
  corner-node((3, 2), [NE label], name: "bne", corner: "north-east")
  corner-node((-3, -1), [SW label], name: "bsw", corner: "south-west")
  corner-node((3, -1), [SE label], name: "bse", corner: "south-east")

  // All four corners on a single large node for comparison
  node((0, -4), [center], name: "bc", stroke: black, fill: luma(220), width: 4cm, height: 2cm)
  large-corner-node((0, -4), [NW], "bcnw", "north-west")
  large-corner-node((0, -4), [NE], "bcne", "north-east")
  large-corner-node((0, -4), [SW], "bcsw", "south-west")
  large-corner-node((0, -4), [SE], "bcse", "south-east")
})
