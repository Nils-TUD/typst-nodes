// Test: node placement relative to an element inside a named group
#import "@preview/cetz:0.5.2"
#import "/src/lib.typ": canvas, node

#set page(width: 3cm, height: 2cm, margin: 5pt)

#canvas({
  cetz.draw.group(name: "group", {
    node((0, 0), [A], name: "inner", stroke: black, width: 1cm, height: .7cm)
  })

  node((north-of: ("group.inner", .4cm)), [Top], name: "top", stroke: blue)
  node((east-of: ("group.inner", .4cm)), [Right], name: "right", stroke: red)
})
