#import "@preview/cetz:0.4.2"

#let get-element-size(ctx, name) = {
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
    }
    else if drawable.type == "content" {
      let (x, y, _, w, h,) = drawable.pos + (drawable.width, drawable.height)
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

#let resolve-outer(ctx, dir, el, dist, align, width, height) = {
  // "north-of" -> "north"
  let edge = dir.slice(0, -3)
  // Resolve the element's edge anchor
  let edge-pt = cetz.coordinate.resolve(ctx, (name: el, anchor: edge)).at(1)

  // Calculate alignment offset
  let align-offset = (0, 0, 0)
  if align != "center" {
    let el-size = get-element-size(ctx, el)
    if edge == "north" or edge == "south" {
      let off = width / 2 - el-size.at(0) / 2
      if align == "left" {
        align-offset = (off, 0, 0)
      }
      else if align == "right" {
        align-offset = (-off, 0, 0)
      }
    }
    else {
      let off = height / 2 - el-size.at(1) / 2
      if align == "bottom" {
        align-offset = (0, off, 0)
      }
      else if align == "top" {
        align-offset = (0, -off, 0)
      }
    }
  }

  // determine normal vector for given edge/corner
  let normal = if edge == "north" { (0, 1, 0) }
  else if edge == "south" { (0, -1, 0) }
  else if edge == "east" { (1, 0, 0) }
  else if edge == "west" { (-1, 0, 0) }
  else if edge == "north-east" { (1, 1, 0) }
  else if edge == "north-west" { (-1, 1, 0) }
  else if edge == "south-east" { (1, -1, 0) }
  else if edge == "south-west" { (-1, -1, 0) }

  // Adjust origin by half the new rectangle's size to align edges
  let nx = normal.at(0)
  let ny = normal.at(1)
  let halfproj = calc.abs(nx) * (width / 2) + calc.abs(ny) * (height / 2)
  let shift = if edge.contains("-") { dist } else { dist + halfproj }

  // determine adjustment to center anchor
  let (ax, ay) = if edge == "south-west" { (-width, -height) }
  else if edge == "south-east" { (0, -height) }
  else if edge == "north-west" { (-width, 0) }
  else if edge == "north-east" { (0, 0) }
  else { (-width / 2, -height/ 2) }

  let offset = cetz.vector.add(
    cetz.vector.add(
      (nx * shift, ny * shift, 0),
      align-offset,
    ),
    (ax, ay, 0),
  )
  (rel: offset, to: edge-pt)
}

#let resolve-inner(pos, el, dist, width, height) = {
  let y-start = if pos.starts-with("in-north") {
    -height - dist
  }
  else if pos.starts-with("in-south") {
    dist
  }
  else {
    -height / 2
  }

  let x-start = if pos.ends-with("west") {
    dist
  }
  else if pos.ends-with("east") {
    -width - dist
  }
  else {
    -width / 2
  }

  (
    (rel: (x-start, y-start), to: el + "." + pos.slice(3)),
    (rel: (width, height))
  )
}

#let resolve-between(ctx, el-a, el-b) = {
  let pt-a = cetz.coordinate.resolve(ctx, (name: el-a, anchor: "center")).at(1)
  let pt-b = cetz.coordinate.resolve(ctx, (name: el-b, anchor: "center")).at(1)
  cetz.vector.scale(cetz.vector.add(pt-a, pt-b), .5)
}

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
  ..style
) = {
  cetz.draw.get-ctx((ctx) => {
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
    }
    else {
      (width, height)
    }

    // determine location and size
    let outer = (
      "east-of", "west-of", "north-of", "south-of",
      "north-east-of", "north-west-of", "south-east-of", "south-west-of",
    )
    let inner = (
      "in-north", "in-south", "in-west", "in-east",
      "in-north-west", "in-north-east", "in-south-west", "in-south-east"
    )
    let (anchor, loc, size) = if type(origin) == dictionary {
      let (dir, spec) = origin.pairs().first()

      if dir == "between" {
        let (el-a, el-b) = spec
        // make size absolute
        let width = cetz.util.resolve-number(ctx, width)
        let height = cetz.util.resolve-number(ctx, height)
        let mid = resolve-between(ctx, el-a, el-b)
        let loc = cetz.vector.add(mid, (-width / 2, -height / 2, 0))
        ("center", loc, (rel: (width, height)))
      }
      else {
        let (el, dist, align) = if type(spec) == array {
          if spec.len() == 2 {
            let (el, dist) = spec
            (el, dist, "center")
          }
          else {
            spec
          }
        }
        else {
          (spec, 0, "center")
        }
        let dist = cetz.util.resolve-number(ctx, dist)

        if dir in outer {
          // make size absolute
          let width = cetz.util.resolve-number(ctx, width)
          let height = cetz.util.resolve-number(ctx, height)

          (
            "center",
            resolve-outer(ctx, dir, el, dist, align, width, height),
            (rel: (width, height))
          )
        }
        else if dir in inner {
          // resolve ratios to container-relative sizes
          let (width, height) = if type(width) == ratio or type(height) == ratio {
            let con-size = get-element-size(ctx, el)
            let width = if type(width) == ratio { float(width * con-size.at(0)) } else { width }
            let height = if type(height) == ratio { float(height * con-size.at(1)) } else { height }
            (width, height)
          }
          else {
            (width, height)
          }

          // make size absolute
          let width = cetz.util.resolve-number(ctx, width)
          let height = cetz.util.resolve-number(ctx, height)

          let (loc, size) = resolve-inner(dir, el, dist, width, height)
          ("center", loc, size)
        }
        else {
          (style.at("anchor", default: "center"), origin, (rel: (width, height)))
        }
      }
    }
    else {
      (style.at("anchor", default: "center"), origin, (rel: (width, height)))
    }

    let name = style.at("name", default: "__r__")
    cetz.draw.rect(
      loc,
      size,
      anchor: anchor,
      name: name,
      ..style
    )

    let body-anc = name + "." + body-pos
    let (pos, anc) = if body-pos == "north" {
      ((rel: (0, -body-dist), to: body-anc), "north")
    }
    else if body-pos == "south" {
      ((rel: (0, body-dist), to: body-anc), "south")
    }
    else if body-pos == "west" {
      ((rel: (body-dist, 0), to: body-anc), "west")
    }
    else if body-pos == "east" {
      ((rel: (-body-dist, 0), to: body-anc), "east")
    }
    else {
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

  cetz.draw.get-ctx((ctx) => {
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

    cetz.draw.get-ctx((ctx) => {
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
        a-shifted, target,
        name: line-name,
        ..style,
      )

      if label != none {
        _edge-place-label(line-name, label, label-pos, label-dist, label-align, label-angle, label-inset)
      }
    })
  } else {
    // --- 3-segment routed line ---
    // Requires exactly 2 positional points (start and end).
    //
    // shift offsets start and end in the direction of the middle segment:
    //   "north"/"south": middle is horizontal → shift is an x offset
    //   "west"/"east":   middle is vertical   → shift is a y offset
    //
    // shift can be a single value (same for both endpoints) or an array
    // (shift-a, shift-b) for independent per-endpoint control.
    let (pt-start, pt-end) = (points.at(0), points.at(1))

    cetz.draw.get-ctx((ctx) => {
      let a = cetz.coordinate.resolve(ctx, pt-start).at(1)
      let b = cetz.coordinate.resolve(ctx, pt-end).at(1)

      // Resolve shift into two scalar values
      let (sa, sb) = if type(shift) == array {
        (cetz.util.resolve-number(ctx, shift.at(0)),
         cetz.util.resolve-number(ctx, shift.at(1)))
      } else {
        let s = cetz.util.resolve-number(ctx, shift)
        (s, s)
      }

      let bend-val = if bend != auto {
        cetz.util.resolve-number(ctx, bend)
      } else {
        // Default: half the span in the routing direction
        if routing == "south" or routing == "north" {
          calc.abs(b.at(0) - a.at(0)) / 2
        } else {
          calc.abs(b.at(1) - a.at(1)) / 2
        }
      }
      assert(bend-val != 0, message: "The bend value cannot be 0 (wrong routing direction?)")

      // Compute the 2 intermediate waypoints, applying shift to the x (for
      // north/south) or y (for west/east) of each endpoint.
      //
      //   "south":  A → down by bend → across → up to B
      //   "north":  A → up by bend → across → down to B
      //   "west":   A → left by bend → across → right to B
      //   "east":   A → right by bend → across → left to B
      let (a-shifted, b-shifted, p1, p2) = if routing == "south" {
        let ax = a.at(0) + sa
        let bx = b.at(0) + sb
        (
          (ax, a.at(1), a.at(2)),
          (bx, b.at(1), b.at(2)),
          (ax, a.at(1) - bend-val, a.at(2)),
          (bx, a.at(1) - bend-val, a.at(2)),
        )
      } else if routing == "north" {
        let ax = a.at(0) + sa
        let bx = b.at(0) + sb
        (
          (ax, a.at(1), a.at(2)),
          (bx, b.at(1), b.at(2)),
          (ax, a.at(1) + bend-val, a.at(2)),
          (bx, a.at(1) + bend-val, a.at(2)),
        )
      } else if routing == "west" {
        let ay = a.at(1) + sa
        let by = b.at(1) + sb
        (
          (a.at(0), ay, a.at(2)),
          (b.at(0), by, b.at(2)),
          (a.at(0) - bend-val, ay, a.at(2)),
          (a.at(0) - bend-val, by, a.at(2)),
        )
      } else if routing == "east" {
        let ay = a.at(1) + sa
        let by = b.at(1) + sb
        (
          (a.at(0), ay, a.at(2)),
          (b.at(0), by, b.at(2)),
          (a.at(0) + bend-val, ay, a.at(2)),
          (a.at(0) + bend-val, by, a.at(2)),
        )
      }

      // Draw the full 3-segment line
      cetz.draw.line(
        a-shifted, p1, p2, b-shifted,
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
  }
}
