// Test: body-pos and body-dist
//
// body-pos places the label content flush against one of the node's edges
// (instead of centered), offset outward by body-dist.
// Also tests body-align (left/center/right alignment of the label text).
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#canvas({
  // body-pos: "north" — label anchored to top edge, pushed inward by body-dist
  node(
    (-3, 2),
    [North label],
    name: "bn",
    stroke: black,
    fill: silver,
    width: 3cm,
    height: 1.5cm,
    body-pos: "north",
    body-dist: .15cm,
  )

  // body-pos: "south"
  node(
    (3, 2),
    [South label],
    name: "bs",
    stroke: black,
    fill: silver,
    width: 3cm,
    height: 1.5cm,
    body-pos: "south",
    body-dist: .15cm,
  )

  // body-pos: "west"
  node(
    (-3, -1),
    [W],
    name: "bw",
    stroke: black,
    fill: silver,
    width: 3cm,
    height: 1.5cm,
    body-pos: "west",
    body-dist: .15cm,
  )

  // body-pos: "east"
  node(
    (3, -1),
    [E],
    name: "be",
    stroke: black,
    fill: silver,
    width: 3cm,
    height: 1.5cm,
    body-pos: "east",
    body-dist: .15cm,
  )

  // body-align: left vs right on a wide node with centered body-pos
  node(
    (-3, -4),
    [left #linebreak() aligned #linebreak() text],
    name: "bal",
    stroke: black,
    fill: luma(220),
    width: 2cm,
    height: 2cm,
    body-align: left,
  )

  node(
    (3, -4),
    [right #linebreak() aligned #linebreak() text],
    name: "bar",
    stroke: black,
    fill: luma(220),
    width: 2cm,
    height: 2cm,
    body-align: right,
  )
})
