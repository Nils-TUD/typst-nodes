#import "@preview/cetz:0.4.2"

#let warn(body) = {
  let my-message = [#(label(repr(body)))]
}

#let _outer-coords = (
  "east-of",
  "west-of",
  "north-of",
  "south-of",
  "north-east-of",
  "north-west-of",
  "south-east-of",
  "south-west-of",
)

#let _inner-coords = (
  "in-north",
  "in-south",
  "in-west",
  "in-east",
  "in-north-west",
  "in-north-east",
  "in-south-west",
  "in-south-east",
  "in-center",
)

#let _nodes-canvas-key = "__nodes_canvas__"

#let _assert-nodes-canvas(ctx) = {
  assert(
    ctx.shared-state.at(_nodes-canvas-key, default: false),
    message: "nodes.node and nodes.edge must be used inside nodes.canvas(...)",
  )
}

#let _parse-placement-spec(spec) = {
  if type(spec) == array {
    if spec.len() == 2 {
      let (el, dist) = spec
      (el, dist, "center")
    } else {
      spec
    }
  } else {
    (spec, 0, "center")
  }
}

#let _get-element-size(ctx, name) = {
  import cetz: drawable, path-util

  let element = ctx.nodes.at(name)
  let min-pt = (calc.inf, calc.inf, calc.inf)
  let max-pt = (-calc.inf, -calc.inf, -calc.inf)

  for drawable in drawable.filter-tagged(element.drawables, drawable.TAG.no-bounds) {
    if drawable.type == "path" {
      for pt in path-util.bounds(drawable.segments) {
        min-pt = (
          calc.min(min-pt.at(0), pt.at(0)),
          calc.min(min-pt.at(1), pt.at(1)),
          calc.min(min-pt.at(2), pt.at(2)),
        )
        max-pt = (
          calc.max(max-pt.at(0), pt.at(0)),
          calc.max(max-pt.at(1), pt.at(1)),
          calc.max(max-pt.at(2), pt.at(2)),
        )
      }
    } else if drawable.type == "content" {
      let (x, y, _, w, h) = drawable.pos + (drawable.width, drawable.height)
      let corners = (
        (x + w / 2, y - h / 2, 0.0),
        (x - w / 2, y + h / 2, 0.0),
      )
      for pt in corners {
        min-pt = (
          calc.min(min-pt.at(0), pt.at(0)),
          calc.min(min-pt.at(1), pt.at(1)),
          calc.min(min-pt.at(2), pt.at(2)),
        )
        max-pt = (
          calc.max(max-pt.at(0), pt.at(0)),
          calc.max(max-pt.at(1), pt.at(1)),
          calc.max(max-pt.at(2), pt.at(2)),
        )
      }
    }
  }

  (
    calc.abs(max-pt.at(0) - min-pt.at(0)),
    calc.abs(max-pt.at(1) - min-pt.at(1)),
    calc.abs(max-pt.at(2) - min-pt.at(2)),
  )
}

#let _resolve-node-size(ctx, width, height, relative-to: none) = {
  let (width, height) = if relative-to != none and (type(width) == ratio or type(height) == ratio) {
    let con-size = _get-element-size(ctx, relative-to)
    let width = if type(width) == ratio { float(width * con-size.at(0)) } else { width }
    let height = if type(height) == ratio { float(height * con-size.at(1)) } else { height }
    (width, height)
  } else {
    (width, height)
  }

  (
    cetz.util.resolve-number(ctx, width),
    cetz.util.resolve-number(ctx, height),
  )
}

#let _resolve-outer(ctx, dir, el, dist, align, width, height) = {
  let edge = dir.slice(0, -3)
  let edge-pt = cetz.coordinate.resolve(ctx, (name: el, anchor: edge)).at(1)

  let align-offset = (0, 0, 0)
  if align != "center" {
    let el-size = _get-element-size(ctx, el)
    if edge == "north" or edge == "south" {
      let off = width / 2 - el-size.at(0) / 2
      if align == "left" {
        align-offset = (off, 0, 0)
      } else if align == "right" {
        align-offset = (-off, 0, 0)
      }
    } else {
      let off = height / 2 - el-size.at(1) / 2
      if align == "bottom" {
        align-offset = (0, off, 0)
      } else if align == "top" {
        align-offset = (0, -off, 0)
      }
    }
  }

  let normal = if edge == "north" { (0, 1, 0) } else if edge == "south" { (0, -1, 0) } else if edge == "east" {
    (1, 0, 0)
  } else if edge == "west" { (-1, 0, 0) } else if edge == "north-east" { (1, 1, 0) } else if edge == "north-west" {
    (-1, 1, 0)
  } else if edge == "south-east" { (1, -1, 0) } else if edge == "south-west" { (-1, -1, 0) }

  let nx = normal.at(0)
  let ny = normal.at(1)
  let halfproj = calc.abs(nx) * (width / 2) + calc.abs(ny) * (height / 2)
  let shift = if edge.contains("-") { dist } else { dist + halfproj }

  let (ax, ay) = if edge == "south-west" { (-width, -height) } else if edge == "south-east" { (0, -height) } else if (
    edge == "north-west"
  ) { (-width, 0) } else if edge == "north-east" { (0, 0) } else { (-width / 2, -height / 2) }

  let offset = cetz.vector.add(
    cetz.vector.add(
      (nx * shift, ny * shift, 0),
      align-offset,
    ),
    (ax, ay, 0),
  )
  (rel: offset, to: edge-pt)
}

#let _resolve-inner(pos, el, dist, width, height) = {
  let y-start = if pos.starts-with("in-north") {
    -height - dist
  } else if pos.starts-with("in-south") {
    dist
  } else {
    -height / 2
  }

  let x-start = if pos.ends-with("west") {
    dist
  } else if pos.ends-with("east") {
    -width - dist
  } else {
    -width / 2
  }

  (
    (rel: (x-start, y-start), to: el + "." + pos.slice(3)),
    (rel: (width, height)),
  )
}

#let _resolve-between(ctx, el-a, el-b) = {
  let pt-a = cetz.coordinate.resolve(ctx, el-a).at(1)
  let pt-b = cetz.coordinate.resolve(ctx, el-b).at(1)
  cetz.vector.scale(cetz.vector.add(pt-a, pt-b), .5)
}

#let _is-node-placement(c) = {
  (
    type(c) == dictionary
      and c.len() == 1
      and {
        let dir = c.keys().first()
        dir in _outer-coords or dir in _inner-coords or dir == "between"
      }
  )
}

#let _rewrite-node-origin(ctx, c, width, height) = {
  if _is-node-placement(c) {
    let (dir, spec) = c.pairs().first()

    if dir in _outer-coords {
      let (el, dist, align) = _parse-placement-spec(spec)
      let dist = cetz.util.resolve-number(ctx, dist)
      let (width, height) = _resolve-node-size(ctx, width, height)
      _resolve-outer(ctx, dir, el, dist, align, width, height)
    } else if dir in _inner-coords {
      let (el, dist, _) = _parse-placement-spec(spec)
      let dist = cetz.util.resolve-number(ctx, dist)
      let (width, height) = _resolve-node-size(ctx, width, height, relative-to: el)
      _resolve-inner(dir, el, dist, width, height).at(0)
    } else {
      let (el-a, el-b) = spec
      let (width, height) = _resolve-node-size(ctx, width, height)
      let mid = _resolve-between(ctx, el-a, el-b)
      cetz.vector.add(mid, (-width / 2, -height / 2, 0))
    }
  } else if type(c) == dictionary {
    let mapped = (:)
    for (k, v) in c.pairs() {
      mapped.insert(k, _rewrite-node-origin(ctx, v, width, height))
    }
    mapped
  } else if type(c) == array {
    c.map(v => _rewrite-node-origin(ctx, v, width, height))
  } else {
    c
  }
}

#let _resolve-node-coordinate(ctx, c) = {
  if type(c) != dictionary or c.len() != 1 {
    return c
  }

  let (dir, spec) = c.pairs().first()
  if dir in _outer-coords {
    let (el, dist, align) = _parse-placement-spec(spec)
    let dist = cetz.util.resolve-number(ctx, dist)
    _resolve-outer(ctx, dir, el, dist, align, 0, 0)
  } else if dir in _inner-coords {
    let (el, dist, _) = _parse-placement-spec(spec)
    let dist = cetz.util.resolve-number(ctx, dist)
    _resolve-inner(dir, el, dist, 0, 0).at(0)
  } else if dir == "between" {
    let (el-a, el-b) = spec
    _resolve-between(ctx, el-a, el-b)
  } else {
    c
  }
}
