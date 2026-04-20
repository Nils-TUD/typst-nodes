// Test: node placed with "between" positioning
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": canvas, node

#set page(width: 8cm, height: 4cm, margin: 5pt)

#canvas({
  node((-2.5, 0), [Left], name: "l", stroke: black)
  node((2.5, 0), [Right], name: "r", stroke: black)
  node((north-of: ("r", 2.5)), [Top], name: "t", stroke: black)

  node(
    (between: ("l", "r")),
    [Mid],
    width: 1.5cm,
    height: .8cm,
    fill: silver,
  )

  node(
    (between: ("r", "t")),
    [Mid],
    width: 2cm,
    height: 1cm,
    fill: red,
    name: "mid",
  )

  node(
    (between: ("l.north", "r.south")),
    [Anchors],
    width: 1.7cm,
    height: .8cm,
    fill: aqua.lighten(60%),
    name: "anchors",
  )

  node(
    (between: ("anchors.north-east", "mid.south-west")),
    [+],
    width: .5cm,
    height: .5cm,
    fill: green.lighten(60%),
  )
})
