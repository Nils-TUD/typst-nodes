#import "@preview/cetz:0.5.2"
#import "../src/lib.typ": canvas, node

#set page(width: 12cm, height: 10cm, margin: 5pt)

#canvas({
  // Reference node
  node((0, 0), [Center], name: "c", stroke: black, fill: luma(240))

  // Outer diagonal with separate distances: (x, y)
  // south-east-of: x=0.5cm, y=1cm
  node((south-east-of: ("c", (0.5cm, 1cm))), [SE (0.5, 1)], name: "se", stroke: red)

  // north-west-of: x=1cm, y=0.5cm
  node((north-west-of: ("c", (1cm, 0.5cm))), [NW (1, 0.5)], name: "nw", stroke: blue)

  // Inner diagonal with separate distances
  node((0, -5), [Parent], name: "p", width: 4cm, height: 3cm, stroke: black)

  // in-south-east: x=0.2cm, y=1cm (from south-east corner)
  node((in-south-east: ("p", (0.2cm, 1cm))), [in-SE], name: "ise", stroke: red, fill: red.lighten(80%))

  // in-north-west: x=1cm, y=0.2cm (from north-west corner)
  node((in-north-west: ("p", (1cm, 0.2cm))), [in-NW], name: "inw", stroke: blue, fill: blue.lighten(80%))

  // body-dist with separate distances
  node(
    (0, 2),
    [Body Dist],
    name: "bd",
    width: 3cm,
    height: 2cm,
    stroke: black,
    body-pos: "north-east",
    body-dist: (1cm, 0.1cm),
  )

  node(
    (4, 2),
    [Body Dist 2],
    name: "bd2",
    width: 3cm,
    height: 2cm,
    stroke: black,
    body-pos: "south-west",
    body-dist: (0.1cm, 1cm),
  )
})
