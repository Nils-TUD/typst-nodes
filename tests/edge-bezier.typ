// Test: quadratic bezier edges with automatic control, explicit control,
// and default bend direction selection.
#import "@preview/cetz:0.5.2"
#import "/src/lib.typ": canvas, edge, node

#set page(width: 12cm, height: 8cm, margin: 5pt)

#canvas({
  node((-4, 2), [A], name: "a", stroke: black)
  node((0, 2), [B], name: "b", stroke: black)
  node((4, 2), [C], name: "c", stroke: black)
  node((-4, -2), [D], name: "d", stroke: black)
  node((0, -2), [E], name: "e", stroke: black)
  node((4, -2), [F], name: "f", stroke: black)
  node((-2, 0), [G], name: "g", stroke: black)

  cetz.draw.set-style(mark: (end: ">"))

  edge("a", "b", routing: "bezier")
  edge("b", "e", routing: "bezier")
  edge("e", "d", routing: "bezier", control: (dir: "south"))
  edge("d", "a", routing: "bezier", control: (dir: "west"))

  cetz.draw.set-style(stroke: red)

  edge("a", "g", routing: "bezier")
  edge("b", "g", routing: "bezier", control: (dir: "north"))
  edge("d", "g", routing: "bezier")
  edge("e", "g", routing: "bezier", control: (dir: "west"))

  cetz.draw.set-style(stroke: blue)

  edge("f.north", "b.east", routing: "bezier", control: "c")
  edge("b.east", "c.west", routing: "bezier", control: (2, 4))
  edge("e", "f.west", routing: "bezier", control: (2, -4))
})
