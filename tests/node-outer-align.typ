// Test: outer placement with explicit alignment
//
// north-of / south-of accept align: "left" | "center" | "right"
//   left  → new node's left edge aligns with reference's left edge
//   right → new node's right edge aligns with reference's right edge
//
// east-of / west-of accept align: "top" | "center" | "bottom"
//   top    → new node's top edge aligns with reference's top edge
//   bottom → new node's bottom edge aligns with reference's bottom edge
#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": node

#set page(width: 10cm, height: 10cm, margin: 5pt)

#cetz.canvas({
  // --- north-of / south-of alignment ---
  // Wide reference node
  node((0, 2), [], name: "ref-ns", width: 4cm, height: .6cm, stroke: black)

  // Narrower nodes placed north-of with left/center/right alignment
  node((north-of: ("ref-ns", .3cm, "left")),   [L], name: "n-left",   width: 1cm, height: .5cm)
  node((north-of: ("ref-ns", .3cm, "center")), [C], name: "n-center", width: 1cm, height: .5cm)
  node((north-of: ("ref-ns", .3cm, "right")),  [R], name: "n-right",  width: 1cm, height: .5cm)

  // Narrower nodes placed south-of with left/center/right alignment
  node((south-of: ("ref-ns", .3cm, "left")),   [L], name: "s-left",   width: 1cm, height: .5cm)
  node((south-of: ("ref-ns", .3cm, "center")), [C], name: "s-center", width: 1cm, height: .5cm)
  node((south-of: ("ref-ns", .3cm, "right")),  [R], name: "s-right",  width: 1cm, height: .5cm)

  // --- east-of / west-of alignment ---
  // Tall reference node
  node((0, -2), [], name: "ref-ew", width: .6cm, height: 3cm, stroke: black)

  // Shorter nodes placed east-of with top/center/bottom alignment
  node((east-of: ("ref-ew", .3cm, "top")),    [T], name: "e-top",    width: .8cm, height: .7cm)
  node((east-of: ("ref-ew", .3cm, "center")), [C], name: "e-center", width: .8cm, height: .7cm)
  node((east-of: ("ref-ew", .3cm, "bottom")), [B], name: "e-bottom", width: .8cm, height: .7cm)

  // Shorter nodes placed west-of with top/center/bottom alignment
  node((west-of: ("ref-ew", .3cm, "top")),    [T], name: "w-top",    width: .8cm, height: .7cm)
  node((west-of: ("ref-ew", .3cm, "center")), [C], name: "w-center", width: .8cm, height: .7cm)
  node((west-of: ("ref-ew", .3cm, "bottom")), [B], name: "w-bottom", width: .8cm, height: .7cm)
})
