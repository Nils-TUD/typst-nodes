#import "@preview/cetz:0.5.2"
#import "../src/lib.typ": canvas, edge, node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#canvas({
  node((0, 0), [A], name: "A", width: 1cm, height: 1cm)
  node((.3, 2), [B], name: "B", width: 1cm, height: 1cm)
  node((3, .3), [C], name: "C", width: 1cm, height: 1cm)
  node((.5, -2), [D], name: "D", width: 1cm, height: 1cm)

  // Straight edge (good for comparison)
  edge("A", "C", stroke: gray + 0.5pt)

  // Horizontal/Vertical routing with border magic
  cetz.draw.set-style(mark: (end: ">"))
  edge("A", "C", routing: "horizontal", stroke: red, label: "H", label-pos: 0.2)
  edge("A", "B", routing: "vertical", stroke: blue, label: "V", label-pos: 0.1)

  // 2-way routing with border magic
  edge("B", "C", routing: "2w-east", stroke: green, label: "2w-E")
  edge("C", "D", routing: "2w-south", stroke: orange, label: "2w-S")

  // 3-way routing with border magic
  edge("D", "A", routing: "3w-west", bend: 1cm, stroke: purple, label: "3w-W", label-pos: -.1)
  edge("A", "C", routing: "3w-south", bend: .5cm, stroke: yellow, label: "3w-S", shift: (0, -.1))
})
