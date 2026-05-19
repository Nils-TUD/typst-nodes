#import "@preview/cetz:0.5.2"

/// Debug helper that materializes `body` as a label containing its `repr(...)`.
///
/// This is mainly useful while developing the package itself.
#let warn(body) = {
  let my-message = [#(label(repr(body)))]
}

#let nodes-canvas-key = "__nodes_canvas__"

#let _with-anchor(name, anchor) = {
  if type(name) != str or not name.contains(".") {
    return (name: name, anchor: anchor)
  }

  let (root, ..nested) = name.split(".")
  let anchor = if type(anchor) == array {
    nested + anchor
  } else {
    nested + (anchor,)
  }
  (name: root, anchor: anchor)
}

/// Assert that the current CeTZ context was created by `nodes.canvas(...)`.
///
/// Shared helpers that depend on the nodes coordinate resolver call this to
/// fail early with a clearer error message.
#let assert-nodes-canvas(ctx) = {
  assert(
    ctx.shared-state.at(nodes-canvas-key, default: false),
    message: "nodes.node and nodes.edge must be used inside nodes.canvas(...)",
  )
}

/// Resolve an anchor on a named element, including elements inside CeTZ groups.
#let resolve-element-anchor(ctx, name, anchor) = {
  cetz.coordinate.resolve(ctx, _with-anchor(name, anchor)).at(1)
}

/// Return the axis-aligned size `(width, height, depth)` of a named CeTZ node.
///
/// The size is computed from the element's drawable bounds and is used by the
/// coordinate helpers when placing nodes relative to other elements.
#let get-element-size(ctx, name) = {
  let west = resolve-element-anchor(ctx, name, "west")
  let east = resolve-element-anchor(ctx, name, "east")
  let north = resolve-element-anchor(ctx, name, "north")
  let south = resolve-element-anchor(ctx, name, "south")

  (
    calc.abs(east.at(0) - west.at(0)),
    calc.abs(north.at(1) - south.at(1)),
    0,
  )
}
