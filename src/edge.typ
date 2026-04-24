#import "@preview/cetz:0.4.2"
#import "util.typ" as util

// Parse a label-pos value into (seg-num, pos-ratio, dist).
//
// label-pos may be:
//   ratio              -> (default-seg, ratio, default-dist)
//   float              -> (default-seg, 50%,   float)
//   (ratio,)           -> (default-seg, ratio, default-dist)
//   (ratio, dist)      -> (default-seg, ratio, dist)
//   (seg, ratio)       -> (seg,         ratio, default-dist)
//   (seg, ratio, dist) -> (seg,         ratio, dist)
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
        (a, b, default-dist)
      } else {
        (default-seg, a, float(b))
      }
    } else if label-pos.len() == 3 {
      (label-pos.at(0), label-pos.at(1), float(label-pos.at(2)))
    } else {
      panic("label-pos array must have 1-3 elements")
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
// seg-names  - array of named auxiliary line names, one per segment, in order.
// seg-num    - 1-based index into seg-names.
// pos-ratio  - position along the chosen segment (e.g. 50%).
// dist       - signed perpendicular offset in CeTZ units, using a canonical
//              convention based on the segment's axis (not its travel direction):
//                horizontal segment: positive = north (up),  negative = south (down)
//                vertical segment:   positive = east  (right), negative = west (left)
//                0 -> center of label box placed directly on the line.
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
    let pos-pct = calc.round(float(pos-ratio) * 100)
    let pt = cetz.coordinate.resolve(ctx, (name: seg-name, anchor: str(pos-pct) + "%")).at(1)

    if dist == 0.0 {
      cetz.draw.content(pt, anchor: "center", align(label-align)[#label-content])
    } else {
      let (label-width, label-height) = cetz.util.measure(ctx, label-content)
      let p0 = cetz.coordinate.resolve(ctx, (name: seg-name, anchor: "0%")).at(1)
      let p1 = cetz.coordinate.resolve(ctx, (name: seg-name, anchor: "100%")).at(1)
      let dx = calc.abs(p1.at(0) - p0.at(0))
      let dy = calc.abs(p1.at(1) - p0.at(1))
      let _eps = 1e-6

      let (normal-x, normal-y) = if dy < _eps {
        (0.0, 1.0)
      } else if dx < _eps {
        (1.0, 0.0)
      } else {
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
///   - bare `ratio` (e.g. `50%`) -- position on the default segment, default
///     distance.
///   - bare `float` (e.g. `0.5`) -- default segment, default position, given
///     distance.
///   - `(ratio,)` -- position on the default segment, default distance.
///   - `(ratio, dist)` -- position and distance on the default segment.
///   - `(seg, ratio)` -- explicit 1-based segment number and position, default
///     distance.
///   - `(seg, ratio, dist)` -- all three explicit.
///
///   `dist` is a signed CeTZ-unit offset perpendicular to the segment:
///   - `dist > 0` -> label north of a horizontal segment / east of a vertical
///     segment; the near edge of the box is `dist` from the line.
///   - `dist < 0` -> label south of a horizontal segment / west of a vertical
///     segment; the near edge of the box is `|dist|` from the line.
///   - `dist = 0` -> center of the label box placed directly on the line.
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
///   (e.g. `name`, `stroke`, `mark`, ...).
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

  cetz.draw.get-ctx(ctx => util.assert-nodes-canvas(ctx))

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
