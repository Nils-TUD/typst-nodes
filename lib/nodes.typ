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
