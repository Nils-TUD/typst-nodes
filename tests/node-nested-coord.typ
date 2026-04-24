// Test: nested nodes coordinates inside standard CeTZ coordinate expressions
#import "@preview/cetz:0.4.2"
#import "/src/lib.typ": canvas, node

#set page(width: 9cm, height: 6cm, margin: 5pt)

#canvas({
  import cetz.draw: circle, line

  node((0, 0), [A], name: "a", stroke: black)
  node((east-of: ("a", 2cm)), [B], name: "b", stroke: black)
  node((east-of: ("a", 1cm)), [C], name: "c", width: .8cm, height: .8cm, stroke: black)
  node((rel: (0, 0), to: (east-of: ("a", 1cm))), [C], name: "c-nested", width: .8cm, height: .8cm, stroke: blue)
  circle((rel: (0, 1cm), to: (east-of: ("a", 1cm))), radius: .2cm, fill: red, stroke: none)
  line(
    (rel: (0, .5cm), to: (east-of: "a")),
    (rel: (0, -.5cm), to: (between: ("a", "b"))),
    stroke: blue,
  )
})
