// Test: node placed with "between" positioning
#import "@preview/cetz:0.4.2"
#import "/lib/nodes.typ": node

#set page(width: 8cm, height: 4cm, margin: 5pt)

#cetz.canvas({
  node((-2.5, 0), [Left],  name: "l", stroke: black)
  node(( 2.5, 0), [Right], name: "r", stroke: black)
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
  )
})
