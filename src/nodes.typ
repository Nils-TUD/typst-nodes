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
  let pt-a = cetz.coordinate.resolve(ctx, (name: el-a, anchor: "center")).at(1)
  let pt-b = cetz.coordinate.resolve(ctx, (name: el-b, anchor: "center")).at(1)
  cetz.vector.scale(cetz.vector.add(pt-a, pt-b), .5)
}

#let _is-node-placement(c) = {
  type(c) == dictionary and c.len() == 1 and {
    let dir = c.keys().first()
    dir in _outer-coords or dir in _inner-coords or dir == "between"
  }
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
///   - `"between"`: centres the node between two existing elements. The value
///     must be a two-element array `(el-a, el-b)`.
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

    // determine content width and height
    let (width, height) = if width == auto or height == auto {
      let (cw, ch) = cetz.util.measure(ctx, body)
      // cetz.util.measure returns the size of the unrotated body, so we need
      // to compute the axis-aligned bounding box of the rotated rectangle.
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
    } else {
      (width, height)
    }

    // determine location and size
    _assert-nodes-canvas(ctx)
    let origin = if _is-node-placement(origin) {
      origin
    } else {
      _rewrite-node-origin(ctx, origin, width, height)
    }
    let (anchor, loc, size) = if type(origin) == dictionary {
      let (dir, spec) = origin.pairs().first()

      if dir == "between" {
        let (el-a, el-b) = spec
        let (width, height) = _resolve-node-size(ctx, width, height)
        let mid = _resolve-between(ctx, el-a, el-b)
        let loc = cetz.vector.add(mid, (-width / 2, -height / 2, 0))
        ("center", loc, (rel: (width, height)))
      } else {
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
    } else {
      (style.at("anchor", default: "center"), origin, (rel: (width, height)))
    }

    let name = style.at("name", default: "__r__")
    cetz.draw.rect(
      loc,
      size,
      anchor: anchor,
      name: name,
      ..style,
    )

    let body-anc = name + "." + body-pos
    let (pos, anc) = if body-pos == "north" {
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
    cetz.draw.content(pos, anchor: anc, align(body-align)[#body])
  })
}

#let _edge-place-label(
  label-name,
  label,
  label-pos,
  label-dist,
  label-align,
  label-angle,
  label-inset,
) = {
  // Parse label-pos: can be just a ratio (defaults to "north") or (ratio, side)
  let (pos-ratio, side) = if type(label-pos) == array {
    label-pos
  } else {
    (label-pos, "north")
  }

  cetz.draw.get-ctx(ctx => {
    let label-content = box(inset: label-inset, rotate(label-angle)[#label])

    // Resolve the position along the line path
    let pos-pct = float(pos-ratio) * 100
    let pt = cetz.coordinate.resolve(ctx, (name: label-name, anchor: repr(pos-pct) + "%")).at(1)

    // The side determines the direction to offset and the anchor used to
    // place the label box flush against the line point.
    //   side "north" -> label sits above -> anchor its "south" edge at the point
    //   side "south" -> label sits below -> anchor its "north" edge
    //   side "west"  -> label sits left  -> anchor its "east" edge
    //   side "east"  -> label sits right -> anchor its "west" edge
    let (anchor, nx, ny) = if side == "north" {
      ("south", 0, 1)
    } else if side == "south" {
      ("north", 0, -1)
    } else if side == "west" {
      ("east", -1, 0)
    } else if side == "east" {
      ("west", 1, 0)
    }

    // Apply the additional perpendicular distance
    let dist = cetz.util.resolve-number(ctx, label-dist)
    let label-pt = (pt.at(0) + nx * dist, pt.at(1) + ny * dist, pt.at(2))

    cetz.draw.content(label-pt, anchor: anchor, align(label-align)[#label-content])
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
///   controls how far the route bends before turning; defaults to half the
///   span between the endpoints. `shift` offsets each endpoint along the
///   middle segment direction and may be a single value or a `(shift-a,
///   shift-b)` array for independent per-endpoint control.
///
/// - `label` (`content` or `none`) -- Label to render alongside the edge.
///   Defaults to `none`.
/// - `label-pos` (`ratio` or `array`) -- Position of the label along the
///   line. Either a bare ratio (e.g. `50%`) which defaults to the `"north"`
///   side, or a two-element array `(ratio, side)` where `side` is one of
///   `"north"`, `"south"`, `"east"`, `"west"`. Defaults to `(50%, "north")`.
/// - `label-dist` (`length`) -- Perpendicular distance between the line and
///   the label. Defaults to `0`.
/// - `label-align` (`alignment`) -- Typst alignment applied to the label
///   content. Defaults to `center`.
/// - `label-angle` (`angle`) -- Rotation applied to the label content.
///   Defaults to `0deg`.
/// - `label-inset` (`length`) -- Inset applied around the label content box.
///   Defaults to `0.3em`.
/// - `routing` (`none` or `string`) -- Routing strategy. One of `none`,
///   `"horizontal"`, `"vertical"`, `"2w-north"`, `"2w-south"`, `"2w-east"`,
///   `"2w-west"`, `"3w-north"`, `"3w-south"`, `"3w-east"`, `"3w-west"`.
///   Defaults to `none`.
/// - `bend` (`auto` or `length`) -- Bend distance for 3-segment routing.
///   Must be non-zero when supplied explicitly. Defaults to `auto`.
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
  label-pos: (50%, "north"),
  label-dist: 0,
  label-align: center,
  label-angle: 0deg,
  label-inset: .3em,
  routing: none,
  bend: auto,
  shift: 0,
  ..args,
) = {
  // Separate positional (coordinates) from named (style) arguments
  let points = args.pos()
  let style = args.named()

  // Extract name from style
  let user-name = style.at("name", default: none)
  let line-name = if user-name != none { user-name } else { "__edge__" }
  if "name" in style {
    let _ = style.remove("name")
  }

  cetz.draw.get-ctx(ctx => _assert-nodes-canvas(ctx))

  let routing-kind = if routing != none and type(routing) == str and routing.starts-with("2w-") {
    "2w"
  } else if routing != none and type(routing) == str and routing.starts-with("3w-") {
    "3w"
  } else {
    none
  }
  let routing-dir = if routing-kind != none { routing.slice(3) } else { none }

  if routing == none {
    // --- Straight line (no routing) — shift is ignored ---
    cetz.draw.line(
      ..points,
      name: line-name,
      ..style,
    )

    if label != none {
      _edge-place-label(line-name, label, label-pos, label-dist, label-align, label-angle, label-inset)
    }
  } else if routing == "horizontal" or routing == "vertical" {
    // --- Single straight segment (horizontal or vertical) ---
    // Requires exactly 2 positional points (start and end).
    //   "horizontal":  A → (B.x, A.y)  — purely horizontal at A's y
    //   "vertical":    A → (A.x, B.y)  — purely vertical at A's x
    //
    // shift offsets the line perpendicular to its direction:
    //   "horizontal": shifts vertically (y offset)
    //   "vertical":   shifts horizontally (x offset)
    assert(points.len() == 2, message: "horizontal/vertical routing requires exactly 2 points")
    let (pt-start, pt-end) = (points.at(0), points.at(1))

    cetz.draw.get-ctx(ctx => {
      let a = cetz.coordinate.resolve(ctx, pt-start).at(1)
      let b = cetz.coordinate.resolve(ctx, pt-end).at(1)
      let s = cetz.util.resolve-number(ctx, shift)

      let (a-shifted, target) = if routing == "horizontal" {
        (
          (a.at(0), a.at(1) + s, a.at(2)),
          (b.at(0), a.at(1) + s, a.at(2)),
        )
      } else {
        (
          (a.at(0) + s, a.at(1), a.at(2)),
          (a.at(0) + s, b.at(1), a.at(2)),
        )
      }

      cetz.draw.line(
        a-shifted,
        target,
        name: line-name,
        ..style,
      )

      if label != none {
        _edge-place-label(line-name, label, label-pos, label-dist, label-align, label-angle, label-inset)
      }
    })
  } else if routing-kind == "2w" {
    // --- 2-segment routed line ---
    assert(points.len() == 2, message: "2-way routing requires exactly 2 points")
    let (pt-start, pt-end) = (points.at(0), points.at(1))

    cetz.draw.get-ctx(ctx => {
      let a = cetz.coordinate.resolve(ctx, pt-start).at(1)
      let b = cetz.coordinate.resolve(ctx, pt-end).at(1)
      let (s1, s2) = if type(shift) == array {
        (cetz.util.resolve-number(ctx, shift.at(0)), cetz.util.resolve-number(ctx, shift.at(1)))
      } else {
        let s = cetz.util.resolve-number(ctx, shift)
        (s, s)
      }

      let (a-shifted, b-shifted, elbow, label-start, label-end) = if routing-dir == "north" or routing-dir == "south" {
        let ax = a.at(0) + s1
        let bx = b.at(0)
        let ay = a.at(1)
        let by = b.at(1) + s2
        let a-shifted = (ax, ay, a.at(2))
        let elbow = (ax, by, a.at(2))
        let b-shifted = (bx, by, b.at(2))
        (a-shifted, b-shifted, elbow, elbow, (bx, by, a.at(2)))
      } else if routing-dir == "east" or routing-dir == "west" {
        let ay = a.at(1) + s1
        let by = b.at(1)
        let ax = a.at(0)
        let bx = b.at(0) + s2
        let a-shifted = (ax, ay, a.at(2))
        let elbow = (bx, ay, a.at(2))
        let b-shifted = (bx, by, b.at(2))
        (a-shifted, b-shifted, elbow, elbow, (bx, by, a.at(2)))
      } else {
        panic("edge: unsupported 2-way routing \"" + routing + "\"")
      }

      cetz.draw.line(
        a-shifted,
        elbow,
        b-shifted,
        name: line-name,
        ..style,
      )

      if label != none {
        let seg-name = line-name + "__seg2__"
        cetz.draw.line(label-start, label-end, name: seg-name, stroke: none)
        _edge-place-label(seg-name, label, label-pos, label-dist, label-align, label-angle, label-inset)
      }
    })
  } else if routing-kind == "3w" {
    // --- 3-segment routed line ---
    // Requires exactly 2 positional points (start and end).
    //
    // shift offsets start and end in the direction of the middle segment:
    //   "3w-north"/"3w-south": middle is horizontal → shift is an x offset
    //   "3w-west"/"3w-east":   middle is vertical   → shift is a y offset
    //
    // shift can be a single value (same for both endpoints) or an array
    // (shift-a, shift-b) for independent per-endpoint control.
    assert(points.len() == 2, message: "3-way routing requires exactly 2 points")
    let (pt-start, pt-end) = (points.at(0), points.at(1))

    cetz.draw.get-ctx(ctx => {
      let a = cetz.coordinate.resolve(ctx, pt-start).at(1)
      let b = cetz.coordinate.resolve(ctx, pt-end).at(1)

      // Resolve shift into two scalar values
      let (sa, sb) = if type(shift) == array {
        (cetz.util.resolve-number(ctx, shift.at(0)), cetz.util.resolve-number(ctx, shift.at(1)))
      } else {
        let s = cetz.util.resolve-number(ctx, shift)
        (s, s)
      }

      // Floating-point arithmetic can produce near-zero values indistinguishable
      // from zero when the two anchors are nominally at the same coordinate.
      // Use an epsilon threshold so we catch those cases too.
      let _eps = 1e-10
      let bend-val = if bend != auto {
        let v = cetz.util.resolve-number(ctx, bend)
        assert(v != 0, message: "bend must be non-zero")
        v
      } else {
        // Default: half the span in the routing direction
        if routing-dir == "south" or routing-dir == "north" {
          let span = calc.abs(b.at(0) - a.at(0))
          if span < _eps {
            panic(
              "edge: routing \""
                + routing
                + "\" requires the two endpoints "
                + "to differ in X, but both have the same X coordinate. "
                + "Either use a different routing direction or supply an explicit bend value.",
            )
          }
          span / 2
        } else {
          let span = calc.abs(b.at(1) - a.at(1))
          if span < _eps {
            panic(
              "edge: routing \""
                + routing
                + "\" requires the two endpoints "
                + "to differ in Y, but both have the same Y coordinate. "
                + "Either use a different routing direction or supply an explicit bend value.",
            )
          }
          span / 2
        }
      }

      // Compute the 2 intermediate waypoints, applying shift to the x (for
      // north/south) or y (for west/east) of each endpoint.
      //
      //   "3w-south":  A → down by bend → across → up to B
      //   "3w-north":  A → up by bend → across → down to B
      //   "3w-west":   A → left by bend → across → right to B
      //   "3w-east":   A → right by bend → across → left to B
      let (a-shifted, b-shifted, p1, p2) = if routing-dir == "south" {
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

      // Draw the full 3-segment line
      cetz.draw.line(
        a-shifted,
        p1,
        p2,
        b-shifted,
        name: line-name,
        ..style,
      )

      if label != none {
        // Draw an invisible line for the middle segment so we can anchor
        // the label percentage to it rather than the full path.
        let mid-name = line-name + "__mid__"
        cetz.draw.line(p1, p2, name: mid-name, stroke: none)
        _edge-place-label(mid-name, label, label-pos, label-dist, label-align, label-angle, label-inset)
      }
    })
  } else {
    panic("edge: unsupported routing " + repr(routing))
  }
}
