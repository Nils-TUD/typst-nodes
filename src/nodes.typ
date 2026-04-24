#import "@preview/cetz:0.4.2"

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

#let _assert-nodes-canvas(ctx) = {
  assert(
    ctx.shared-state.at(_nodes-canvas-key, default: false),
    message: "nodes.node and nodes.edge must be used inside nodes.canvas(...)",
  )
}

#let _get-element-size(ctx, name) = {
  import cetz: drawable, path-util

  let element = ctx.nodes.at(name)
  let min-pt = (calc.inf, calc.inf, calc.inf)
  let max-pt = (-calc.inf, -calc.inf, -calc.inf)

  for drawable in drawable.filter-tagged(element.drawables, drawable.TAG.no-bounds) {
    if drawable.type == "path" {
      // path-util.bounds returns an array of points
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

  // Size vector (width, height, depth)
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
  // "north-of" -> "north"
  let edge = dir.slice(0, -3)
  // Resolve the element's edge anchor
  let edge-pt = cetz.coordinate.resolve(ctx, (name: el, anchor: edge)).at(1)

  // Calculate alignment offset
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

  // determine normal vector for given edge/corner
  let normal = if edge == "north" { (0, 1, 0) } else if edge == "south" { (0, -1, 0) } else if edge == "east" {
    (1, 0, 0)
  } else if edge == "west" { (-1, 0, 0) } else if edge == "north-east" { (1, 1, 0) } else if edge == "north-west" {
    (-1, 1, 0)
  } else if edge == "south-east" { (1, -1, 0) } else if edge == "south-west" { (-1, -1, 0) }

  // Adjust origin by half the new rectangle's size to align edges
  let nx = normal.at(0)
  let ny = normal.at(1)
  let halfproj = calc.abs(nx) * (width / 2) + calc.abs(ny) * (height / 2)
  let shift = if edge.contains("-") { dist } else { dist + halfproj }

  // determine adjustment to center anchor
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

/// Set up a CeTZ canvas with the nodes coordinate resolver registered.
///
/// This mirrors `cetz.canvas(...)`, but additionally enables nested nodes
/// coordinates such as `(rel: (1, 2), to: (east-of: "foo"))` and is required
/// when using `node(...)` or `edge(...)`.
#let canvas(length: 1cm, baseline: none, debug: false, background: none, stroke: none, padding: none, body) = context {
  let init = (
    cetz.draw.register-coordinate-resolver(_resolve-node-coordinate).first(),
    ctx => {
      ctx.shared-state.insert(_nodes-canvas-key, true)
      (ctx: ctx)
    },
  )

  cetz.canvas(
    length: length,
    baseline: baseline,
    debug: debug,
    background: background,
    stroke: stroke,
    padding: padding,
    (
      ..init,
      ..body,
    ),
  )
}

#let _node-resolve-body-size(ctx, body, width, height, body-angle) = {
  if width != auto and height != auto {
    return (width, height)
  }

  let (cw, ch) = cetz.util.measure(ctx, body)
  if body-angle != 0deg {
    let cos-a = calc.abs(calc.cos(body-angle))
    let sin-a = calc.abs(calc.sin(body-angle))
    let rw = cw * cos-a + ch * sin-a
    let rh = cw * sin-a + ch * cos-a
    (cw, ch) = (rw, rh)
  }

  (
    if width == auto { cw } else { width },
    if height == auto { ch } else { height },
  )
}

#let _resolve-node-dict-origin(ctx, origin, width, height, style) = {
  let (dir, spec) = origin.pairs().first()

  if dir == "between" {
    let (el-a, el-b) = spec
    let (width, height) = _resolve-node-size(ctx, width, height)
    let mid = _resolve-between(ctx, el-a, el-b)
    let loc = cetz.vector.add(mid, (-width / 2, -height / 2, 0))
    return ("center", loc, (rel: (width, height)))
  }

  let (el, dist, align) = _parse-placement-spec(spec)
  let dist = cetz.util.resolve-number(ctx, dist)

  if dir in _outer-coords {
    let (width, height) = _resolve-node-size(ctx, width, height)
    (
      "center",
      _resolve-outer(ctx, dir, el, dist, align, width, height),
      (rel: (width, height)),
    )
  } else if dir in _inner-coords {
    let (width, height) = _resolve-node-size(ctx, width, height, relative-to: el)
    let (loc, size) = _resolve-inner(dir, el, dist, width, height)
    ("center", loc, size)
  } else {
    (style.at("anchor", default: "center"), origin, (rel: (width, height)))
  }
}

#let _node-resolve-rect(ctx, origin, width, height, style) = {
  let origin = if _is-node-placement(origin) {
    origin
  } else {
    _rewrite-node-origin(ctx, origin, width, height)
  }

  if type(origin) == dictionary {
    _resolve-node-dict-origin(ctx, origin, width, height, style)
  } else {
    (style.at("anchor", default: "center"), origin, (rel: (width, height)))
  }
}

#let _node-resolve-body-placement(name, body-pos, body-dist) = {
  let body-anc = name + "." + body-pos
  if body-pos == "north" {
    ((rel: (0, -body-dist), to: body-anc), "north")
  } else if body-pos == "south" {
    ((rel: (0, body-dist), to: body-anc), "south")
  } else if body-pos == "west" {
    ((rel: (body-dist, 0), to: body-anc), "west")
  } else if body-pos == "east" {
    ((rel: (-body-dist, 0), to: body-anc), "east")
  } else if body-pos == "north-west" {
    ((rel: (body-dist, -body-dist), to: body-anc), "north-west")
  } else if body-pos == "north-east" {
    ((rel: (-body-dist, -body-dist), to: body-anc), "north-east")
  } else if body-pos == "south-west" {
    ((rel: (body-dist, body-dist), to: body-anc), "south-west")
  } else if body-pos == "south-east" {
    ((rel: (-body-dist, body-dist), to: body-anc), "south-east")
  } else {
    (name, "center")
  }
}

/// Draw a rectangular node (box) with a label on a CeTZ canvas.
///
/// The node's position and size are controlled by `origin`, which can be:
/// - A plain CeTZ coordinate: places the node at that coordinate. The anchor
///   used to attach the node to the coordinate defaults to `"center"` but can
///   be overridden via the `anchor` named style argument.
/// - A dictionary with one of the following keys:
///   - `"north-of"`, `"south-of"`, `"east-of"`, `"west-of"`,
///     `"north-east-of"`, `"north-west-of"`, `"south-east-of"`, `"south-west-of"`:
///     places the node adjacent to an existing named element. The value may be
///     just the element name (string), a two-element array `(name, dist)`, or a
///     three-element array `(name, dist, align)`. The `align` is "left", "right",
///     "top", or "bottom" and specifies the alignment of the new element relative
///     to the element `name`. For example, with "north-of" and "left" the new
///     element is placed north of the `name` and its left border is aligned the
///     left border of `name`.
///   - `"in-north"`, `"in-south"`, `"in-east"`, `"in-west"`,
///     `"in-north-east"`, `"in-north-west"`, `"in-south-east"`, `"in-south-west"`,
///     `"in-center"`:
///     places the node *inside* an existing named element, anchored to the
///     given inner edge/corner/centre. The value follows the same conventions
///     as the outer-placement keys above. `width` and `height` may be given as
///     ratios (e.g. `50%`) to size the child relative to the container.
///   - `"between"`: centres the node between two existing coordinates. The
///     value must be a two-element array `(coord-a, coord-b)` and may include
///     node anchors like `("foo.north", "bar.south")`.
///
/// The remaining arguments are:
/// - `body` (`content`) -- Content rendered inside the node.
/// - `body-pos` (`string`) -- Anchor of the node's rectangle used to attach
///   the body. One of `"center"`, `"north"`, `"south"`, `"east"`, `"west"`.
///   Defaults to `"center"`.
/// - `body-dist` (`length`) -- Additional offset between the body and the
///   `body-pos` anchor. Defaults to `0pt`.
/// - `body-align` (`alignment`) -- Typst alignment applied to the body
///   content. Defaults to `center`.
/// - `body-angle` (`angle`) -- Rotation applied to the body content before
///   measuring and drawing. Defaults to `0deg`.
/// - `width` (`auto` or `length` or `ratio`) -- Width of the node. `auto`
///   sizes to fit the body. A `ratio` is resolved relative to the container
///   when using an inner-placement `origin`. Defaults to `auto`.
/// - `height` (`auto` or `length` or `ratio`) -- Height of the node. Same
///   semantics as `width`. Defaults to `auto`.
/// - `inset` (`length`) -- Inset applied around the body inside the node box.
///   Defaults to `0.3em`.
/// - `..style` -- Additional named CeTZ `rect` style arguments (e.g. `name`,
///   `fill`, `stroke`, `anchor`, `radius`, …).
#let node(
  origin,
  body,
  body-pos: "center",
  body-dist: 0pt,
  body-align: center,
  body-angle: 0deg,
  width: auto,
  height: auto,
  inset: .3em,
  ..style,
) = {
  cetz.draw.get-ctx(ctx => {
    let body = box(inset: inset, rotate(body-angle)[#body])
    let (width, height) = _node-resolve-body-size(ctx, body, width, height, body-angle)

    _assert-nodes-canvas(ctx)
    let (anchor, loc, size) = _node-resolve-rect(ctx, origin, width, height, style)

    let name = style.at("name", default: "__r__")
    cetz.draw.rect(
      loc,
      size,
      anchor: anchor,
      name: name,
      ..style,
    )

    let (pos, anc) = _node-resolve-body-placement(name, body-pos, body-dist)
    cetz.draw.content(pos, anchor: anc, align(body-align)[#body])
  })
}

// Parse a label-pos value into (seg-num, pos-ratio, dist).
//
// label-pos may be:
//   ratio              → (default-seg, ratio, default-dist)
//   float              → (default-seg, 50%,   float)
//   (ratio,)           → (default-seg, ratio, default-dist)
//   (ratio, dist)      → (default-seg, ratio, dist)
//   (seg, ratio)       → (seg,         ratio, default-dist)
//   (seg, ratio, dist) → (seg,         ratio, dist)
//
// seg is an integer (1-based segment number).
// ratio is a Typst ratio (e.g. 50%).
// dist is a plain float in CeTZ units.
//
// default-seg and default-dist are supplied by the caller.
#let _parse-label-pos(label-pos, default-seg: 1, default-dist: 0.3) = {
  if type(label-pos) == ratio {
    (default-seg, label-pos, default-dist)
  } else if type(label-pos) == float or type(label-pos) == int {
    (default-seg, 50%, float(label-pos))
  } else if type(label-pos) == array {
    if label-pos.len() == 1 {
      (default-seg, label-pos.at(0), default-dist)
    } else if label-pos.len() == 2 {
      let (a, b) = (label-pos.at(0), label-pos.at(1))
      if type(a) == int {
        // (seg, ratio)
        (a, b, default-dist)
      } else {
        // (ratio, dist)
        (default-seg, a, float(b))
      }
    } else if label-pos.len() == 3 {
      // (seg, ratio, dist)
      (label-pos.at(0), label-pos.at(1), float(label-pos.at(2)))
    } else {
      panic("label-pos array must have 1–3 elements")
    }
  } else {
    panic("label-pos must be a ratio, float, or array")
  }
}

#let _rotated-rect-support(width, height, angle, nx, ny) = {
  let cos-a = calc.cos(angle)
  let sin-a = calc.sin(angle)
  let width-support = calc.abs(nx * cos-a + ny * sin-a) * width / 2
  let height-support = calc.abs(-nx * sin-a + ny * cos-a) * height / 2

  width-support + height-support
}

// Place a label alongside a named CeTZ line segment.
//
// seg-names  — array of named auxiliary line names, one per segment, in order.
// seg-num    — 1-based index into seg-names.
// pos-ratio  — position along the chosen segment (e.g. 50%).
// dist       — signed perpendicular offset in CeTZ units, using a canonical
//              convention based on the segment's axis (not its travel direction):
//                horizontal segment: positive = north (up),  negative = south (down)
//                vertical segment:   positive = east  (right), negative = west (left)
//                0 → center of label box placed directly on the line.
#let _edge-place-label(
  seg-names,
  label,
  seg-num,
  pos-ratio,
  dist,
  label-align,
  label-angle,
) = {
  let seg-idx = seg-num - 1
  assert(
    seg-idx >= 0 and seg-idx < seg-names.len(),
    message: "label-pos segment number "
      + repr(seg-num)
      + " is out of range (edge has "
      + repr(seg-names.len())
      + " segment(s))",
  )
  let seg-name = seg-names.at(seg-idx)

  cetz.draw.get-ctx(ctx => {
    let label-content = rotate(label-angle)[#label]

    // Resolve position along the segment.
    // CeTZ percent anchors require an integer string like "30%", not "30.0%".
    let pos-pct = calc.round(float(pos-ratio) * 100)
    let pt = cetz.coordinate.resolve(ctx, (name: seg-name, anchor: str(pos-pct) + "%")).at(1)

    if dist == 0.0 {
      cetz.draw.content(pt, anchor: "center", align(label-align)[#label-content])
    } else {
      let (label-width, label-height) = cetz.util.measure(ctx, label-content)

      // Determine the segment's axis from its endpoints so we can apply a
      // canonical sign convention that is independent of travel direction:
      //   horizontal segment → positive dist = north, negative = south
      //   vertical segment   → positive dist = east,  negative = west
      //   diagonal           → fall back to left-hand normal of travel direction
      let p0 = cetz.coordinate.resolve(ctx, (name: seg-name, anchor: "0%")).at(1)
      let p1 = cetz.coordinate.resolve(ctx, (name: seg-name, anchor: "100%")).at(1)
      let dx = calc.abs(p1.at(0) - p0.at(0))
      let dy = calc.abs(p1.at(1) - p0.at(1))
      let _eps = 1e-6

      let (normal-x, normal-y) = if dy < _eps {
        // Horizontal segment: canonical positive normal is (0, 1) = north
        (0.0, 1.0)
      } else if dx < _eps {
        // Vertical segment: canonical positive normal is (1, 0) = east
        (1.0, 0.0)
      } else {
        // Diagonal: canonical positive normal is the left-hand normal of the
        // segment's travel direction.
        let raw-dx = p1.at(0) - p0.at(0)
        let raw-dy = p1.at(1) - p0.at(1)
        let len = calc.sqrt(raw-dx * raw-dx + raw-dy * raw-dy)
        (-raw-dy / len, raw-dx / len)
      }

      let sign = if dist > 0 { 1.0 } else { -1.0 }
      let support = _rotated-rect-support(label-width, label-height, label-angle, normal-x, normal-y)
      let offset = calc.abs(dist) + support
      let label-pt = (
        pt.at(0) + sign * normal-x * offset,
        pt.at(1) + sign * normal-y * offset,
        pt.at(2),
      )
      cetz.draw.content(label-pt, anchor: "center", align(label-align)[#label-content])
    }
  })
}

#let _edge-normalize-args(args) = {
  let points = args.pos()
  let style = args.named()
  let user-name = style.at("name", default: none)
  let line-name = if user-name != none { user-name } else { "__edge__" }
  if "name" in style {
    let _ = style.remove("name")
  }
  (points, style, line-name)
}

#let _edge-parse-routing(routing) = {
  if routing != none and type(routing) == str and routing.starts-with("2w-") {
    ("2w", routing.slice(3))
  } else if routing != none and type(routing) == str and routing.starts-with("3w-") {
    ("3w", routing.slice(3))
  } else {
    (none, none)
  }
}

#let _edge-draw-label(seg-names, label, label-pos, default-seg, label-align, label-angle) = {
  if label == none {
    return
  }

  let (seg-num, pos-ratio, dist) = _parse-label-pos(label-pos, default-seg: default-seg, default-dist: 0.3)
  _edge-place-label(seg-names, label, seg-num, pos-ratio, dist, label-align, label-angle)
}

#let _edge-resolve-shift-pair(ctx, shift) = {
  if type(shift) == array {
    (cetz.util.resolve-number(ctx, shift.at(0)), cetz.util.resolve-number(ctx, shift.at(1)))
  } else {
    let s = cetz.util.resolve-number(ctx, shift)
    (s, s)
  }
}

#let _edge-resolve-axis-points(a, b, routing, shift) = {
  if routing == "horizontal" {
    (
      (a.at(0), a.at(1) + shift, a.at(2)),
      (b.at(0), a.at(1) + shift, a.at(2)),
    )
  } else {
    (
      (a.at(0) + shift, a.at(1), a.at(2)),
      (a.at(0) + shift, b.at(1), a.at(2)),
    )
  }
}

#let _edge-resolve-2w-points(a, b, routing, routing-dir, s1, s2) = {
  if routing-dir == "north" or routing-dir == "south" {
    let ax = a.at(0) + s1
    let bx = b.at(0)
    let ay = a.at(1)
    let by = b.at(1) + s2
    let a-shifted = (ax, ay, a.at(2))
    let elbow = (ax, by, a.at(2))
    let b-shifted = (bx, by, b.at(2))
    (a-shifted, b-shifted, elbow)
  } else if routing-dir == "east" or routing-dir == "west" {
    let ay = a.at(1) + s1
    let by = b.at(1)
    let ax = a.at(0)
    let bx = b.at(0) + s2
    let a-shifted = (ax, ay, a.at(2))
    let elbow = (bx, ay, a.at(2))
    let b-shifted = (bx, by, b.at(2))
    (a-shifted, b-shifted, elbow)
  } else {
    panic("edge: unsupported 2-way routing \"" + routing + "\"")
  }
}

#let _edge-resolve-3w-bend(ctx, a, b, routing-dir, bend) = {
  let _eps = 1e-10

  if bend != auto {
    if type(bend) == str {
      assert(
        bend == "same-dir" or bend == "opposite-dir",
        message: "bend must be auto, \"same-dir\", \"opposite-dir\", or a non-zero length",
      )

      let primary-y-axis = routing-dir == "south" or routing-dir == "north"
      let use-y-span = if bend == "same-dir" { primary-y-axis } else { not primary-y-axis }
      let span = if use-y-span { calc.abs(b.at(1) - a.at(1)) } else { calc.abs(b.at(0) - a.at(0)) }
      return span / 2
    }

    let v = cetz.util.resolve-number(ctx, bend)
    assert(v != 0, message: "bend must be non-zero")
    return v
  }

  let primary-y-axis = routing-dir == "south" or routing-dir == "north"
  let same-axis = if primary-y-axis {
    calc.abs(b.at(1) - a.at(1)) < _eps
  } else {
    calc.abs(b.at(0) - a.at(0)) < _eps
  }
  let use-y-span = if primary-y-axis { not same-axis } else { same-axis }
  let span = if use-y-span { calc.abs(b.at(1) - a.at(1)) } else { calc.abs(b.at(0) - a.at(0)) }
  span / 2
}

#let _edge-resolve-3w-points(a, b, routing, routing-dir, sa, sb, bend-val) = {
  if routing-dir == "south" {
    let ax = a.at(0) + sa
    let bx = b.at(0) + sb
    (
      (ax, a.at(1), a.at(2)),
      (bx, b.at(1), b.at(2)),
      (ax, a.at(1) - bend-val, a.at(2)),
      (bx, a.at(1) - bend-val, a.at(2)),
    )
  } else if routing-dir == "north" {
    let ax = a.at(0) + sa
    let bx = b.at(0) + sb
    (
      (ax, a.at(1), a.at(2)),
      (bx, b.at(1), b.at(2)),
      (ax, a.at(1) + bend-val, a.at(2)),
      (bx, a.at(1) + bend-val, a.at(2)),
    )
  } else if routing-dir == "west" {
    let ay = a.at(1) + sa
    let by = b.at(1) + sb
    (
      (a.at(0), ay, a.at(2)),
      (b.at(0), by, b.at(2)),
      (a.at(0) - bend-val, ay, a.at(2)),
      (a.at(0) - bend-val, by, a.at(2)),
    )
  } else if routing-dir == "east" {
    let ay = a.at(1) + sa
    let by = b.at(1) + sb
    (
      (a.at(0), ay, a.at(2)),
      (b.at(0), by, b.at(2)),
      (a.at(0) + bend-val, ay, a.at(2)),
      (a.at(0) + bend-val, by, a.at(2)),
    )
  } else {
    panic("edge: unsupported 3-way routing \"" + routing + "\"")
  }
}

#let _edge-draw-straight(points, line-name, style, label, label-pos, label-align, label-angle) = {
  cetz.draw.line(
    ..points,
    name: line-name,
    ..style,
  )
  _edge-draw-label((line-name,), label, label-pos, 1, label-align, label-angle)
}

#let _edge-draw-axis(points, line-name, style, label, label-pos, label-align, label-angle, routing, shift) = {
  assert(points.len() == 2, message: "horizontal/vertical routing requires exactly 2 points")
  let (pt-start, pt-end) = (points.at(0), points.at(1))

  cetz.draw.get-ctx(ctx => {
    let a = cetz.coordinate.resolve(ctx, pt-start).at(1)
    let b = cetz.coordinate.resolve(ctx, pt-end).at(1)
    let s = cetz.util.resolve-number(ctx, shift)
    let (a-shifted, target) = _edge-resolve-axis-points(a, b, routing, s)

    cetz.draw.line(
      a-shifted,
      target,
      name: line-name,
      ..style,
    )

    _edge-draw-label((line-name,), label, label-pos, 1, label-align, label-angle)
  })
}

#let _edge-draw-2w(points, line-name, style, label, label-pos, label-align, label-angle, routing, routing-dir, shift) = {
  assert(points.len() == 2, message: "2-way routing requires exactly 2 points")
  let (pt-start, pt-end) = (points.at(0), points.at(1))

  cetz.draw.get-ctx(ctx => {
    let a = cetz.coordinate.resolve(ctx, pt-start).at(1)
    let b = cetz.coordinate.resolve(ctx, pt-end).at(1)
    let (s1, s2) = _edge-resolve-shift-pair(ctx, shift)
    let (a-shifted, b-shifted, elbow) = _edge-resolve-2w-points(a, b, routing, routing-dir, s1, s2)

    cetz.draw.line(
      a-shifted,
      elbow,
      b-shifted,
      name: line-name,
      ..style,
    )

    if label != none {
      let seg1-name = line-name + "__seg1__"
      let seg2-name = line-name + "__seg2__"
      cetz.draw.line(a-shifted, elbow, name: seg1-name, stroke: none)
      cetz.draw.line(elbow, b-shifted, name: seg2-name, stroke: none)
      _edge-draw-label((seg1-name, seg2-name), label, label-pos, 2, label-align, label-angle)
    }
  })
}

#let _edge-draw-3w(points, line-name, style, label, label-pos, label-align, label-angle, routing, routing-dir, bend, shift) = {
  assert(points.len() == 2, message: "3-way routing requires exactly 2 points")
  let (pt-start, pt-end) = (points.at(0), points.at(1))

  cetz.draw.get-ctx(ctx => {
    let a = cetz.coordinate.resolve(ctx, pt-start).at(1)
    let b = cetz.coordinate.resolve(ctx, pt-end).at(1)
    let (sa, sb) = _edge-resolve-shift-pair(ctx, shift)
    let bend-val = _edge-resolve-3w-bend(ctx, a, b, routing-dir, bend)
    let _eps = 1e-10

    if bend-val < _eps {
      panic(
        "edge: routing \""
          + routing
          + "\" requires the two endpoints to differ in X/Y, "
          + "but both have the same X/Y coordinate. Either use a different routing "
          + "direction or supply an explicit (and larger) bend value.",
      )
    }

    let (a-shifted, b-shifted, p1, p2) = _edge-resolve-3w-points(a, b, routing, routing-dir, sa, sb, bend-val)

    cetz.draw.line(
      a-shifted,
      p1,
      p2,
      b-shifted,
      name: line-name,
      ..style,
    )

    if label != none {
      let seg1-name = line-name + "__seg1__"
      let seg2-name = line-name + "__seg2__"
      let seg3-name = line-name + "__seg3__"
      cetz.draw.line(a-shifted, p1, name: seg1-name, stroke: none)
      cetz.draw.line(p1, p2, name: seg2-name, stroke: none)
      cetz.draw.line(p2, b-shifted, name: seg3-name, stroke: none)
      _edge-draw-label((seg1-name, seg2-name, seg3-name), label, label-pos, 2, label-align, label-angle)
    }
  })
}

/// Draw a directed or undirected edge (line) between two CeTZ coordinates or
/// named element anchors, with optional label and routing.
///
/// Routing modes (controlled by `routing`):
/// - `none` (default): a straight line between the two positional points.
///   `shift` is ignored in this mode.
/// - `"horizontal"`: a single horizontal segment at the start point's y
///   coordinate. `shift` offsets the line vertically.
/// - `"vertical"`: a single vertical segment at the start point's x
///   coordinate. `shift` offsets the line horizontally.
/// - `"2w-north"`, `"2w-south"`, `"2w-east"`, `"2w-west"`: a 2-segment
///   orthogonal route with one elbow. `2w-north`/`2w-south` go vertical first
///   to the end point's y coordinate, then horizontal; `2w-east`/`2w-west` go
///   horizontal first to the end point's x coordinate, then vertical. `shift`
///   offsets the two route segments: the first value shifts the first segment,
///   the second value shifts the second segment. For `2w-north`/`2w-south`
///   that means `(x-shift, y-shift)`; for `2w-east`/`2w-west` it means
///   `(y-shift, x-shift)`. A single value applies to both. `bend` is ignored.
/// - `"3w-north"`, `"3w-south"`, `"3w-east"`, `"3w-west"`: a 3-segment
///   orthogonal route. The middle segment runs perpendicular to the named
///   direction (horizontal for north/south, vertical for east/west). `bend`
///   controls how far the route bends before turning. `auto` (the default)
///   chooses half the x distance for `3w-north`/`3w-south` when the endpoints
///   share y and otherwise half the y distance; `3w-east`/`3w-west`
///   analogously choose half the y distance when the endpoints share x and
///   otherwise half the x distance. `"same-dir"` always keeps both outer legs
///   moving in the routing direction, so it uses half the y distance for
///   `3w-north`/`3w-south` and half the x distance for `3w-east`/`3w-west`.
///   `"opposite-dir"` instead returns to the starting axis, so it uses half
///   the x distance for `3w-north`/`3w-south` and half the y distance for
///   `3w-east`/`3w-west`. `shift` offsets each endpoint along the middle
///   segment direction and may be a single value or a `(shift-a, shift-b)`
///   array for independent per-endpoint control.
///
/// - `label` (`content` or `none`) -- Label to render alongside the edge.
///   Defaults to `none`.
/// - `label-pos` -- Controls which segment the label appears on, where along
///   it, and how far from it. Accepts the following forms (all components have
///   defaults: segment = last segment of the route, position = `50%`, distance
///   = `0.3` CeTZ units):
///   - bare `ratio` (e.g. `50%`) — position on the default segment, default
///     distance.
///   - bare `float` (e.g. `0.5`) — default segment, default position, given
///     distance.
///   - `(ratio,)` — position on the default segment, default distance.
///   - `(ratio, dist)` — position and distance on the default segment.
///   - `(seg, ratio)` — explicit 1-based segment number and position, default
///     distance.
///   - `(seg, ratio, dist)` — all three explicit.
///
///   `dist` is a signed CeTZ-unit offset perpendicular to the segment:
///   - `dist > 0` → label north of a horizontal segment / east of a vertical
///     segment; the near edge of the box is `dist` from the line.
///   - `dist < 0` → label south of a horizontal segment / west of a vertical
///     segment; the near edge of the box is `|dist|` from the line.
///   - `dist = 0` → center of the label box placed directly on the line.
///
///   For straight/horizontal/vertical routing there is 1 segment. For `2w-*`
///   routing there are 2 segments; the default is segment 2 (the last). For
///   `3w-*` routing there are 3 segments; the default is segment 2 (the
///   middle). Defaults to `0.3` (default segment, 50%, 0.3 CeTZ units north /
///   east of the line).
/// - `label-align` (`alignment`) -- Typst alignment applied to the label
///   content. Defaults to `center`.
/// - `label-angle` (`angle`) -- Rotation applied to the label content.
///   Defaults to `0deg`.
/// - `routing` (`none` or `string`) -- Routing strategy. One of `none`,
///   `"horizontal"`, `"vertical"`, `"2w-north"`, `"2w-south"`, `"2w-east"`,
///   `"2w-west"`, `"3w-north"`, `"3w-south"`, `"3w-east"`, `"3w-west"`.
///   Defaults to `none`.
/// - `bend` (`auto` or `"same-dir"` or `"opposite-dir"` or `length`) -- Bend
///   distance for 3-segment routing. `"same-dir"` keeps both outer legs moving
///   in the routing direction; `"opposite-dir"` returns to the starting axis.
///   Must be non-zero when supplied explicitly as a length. Defaults to `auto`.
/// - `shift` (`length` or `array`) -- Shift applied to the route segments. For
///   2-segment routing this may be a single value or `(shift-first,
///   shift-second)`.
///   For 3-segment routing this may also be `(shift-a, shift-b)`. Defaults
///   to `0`.
/// - `..args` -- Remaining positional arguments are the line's coordinate
///   points; named arguments are forwarded as CeTZ `line` style options
///   (e.g. `name`, `stroke`, `mark`, …).
#let edge(
  label: none,
  label-pos: 0.3,
  label-align: center,
  label-angle: 0deg,
  routing: none,
  bend: auto,
  shift: 0,
  ..args,
) = {
  let (points, style, line-name) = _edge-normalize-args(args)

  cetz.draw.get-ctx(ctx => _assert-nodes-canvas(ctx))

  let (routing-kind, routing-dir) = _edge-parse-routing(routing)

  if routing == none {
    _edge-draw-straight(points, line-name, style, label, label-pos, label-align, label-angle)
  } else if routing == "horizontal" or routing == "vertical" {
    _edge-draw-axis(points, line-name, style, label, label-pos, label-align, label-angle, routing, shift)
  } else if routing-kind == "2w" {
    _edge-draw-2w(points, line-name, style, label, label-pos, label-align, label-angle, routing, routing-dir, shift)
  } else if routing-kind == "3w" {
    _edge-draw-3w(points, line-name, style, label, label-pos, label-align, label-angle, routing, routing-dir, bend, shift)
  } else {
    panic("edge: unsupported routing " + repr(routing))
  }
}
