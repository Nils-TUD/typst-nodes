// Test: automatic bezier control point with explicit directions via control.
#import "@preview/cetz:0.5.2"
#import "/src/lib.typ": canvas, edge, node

#set page(width: 12cm, height: 10cm, margin: 5pt)

#canvas({
  node((-4, 3), [A], name: "a", stroke: black)
  node((2, 3), [B], name: "b", stroke: black)
  node((-4, 1), [C], name: "c", stroke: black)
  node((2, 1), [D], name: "d", stroke: black)
  node((-4, -1), [E], name: "e", stroke: black)
  node((2, -1), [F], name: "f", stroke: black)
  node((-4, -3), [G], name: "g", stroke: black)
  node((2, -3), [H], name: "h", stroke: black)

  cetz.draw.set-style(mark: (end: ">"))

  edge("a.east", "b.west", routing: "bezier", control: (dir: "north"))
  edge("c.east", "d.west", routing: "bezier", control: (dir: "south"), stroke: blue)
  edge("e.east", "f.west", routing: "bezier", control: (dir: "east"), stroke: red)
  edge("g.east", "h.west", routing: "bezier", control: (dir: "west"), stroke: green)

  edge("e.south", "g.north", routing: "bezier", control: (dir: "west"), stroke: orange)
  edge("e.south", "g.north", routing: "bezier", control: (dir: "east"), stroke: yellow)

  edge("h.north", "f.south", routing: "bezier", control: (dir: "north"), stroke: silver)
})
