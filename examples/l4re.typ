#import "@preview/cetz:0.4.2"
#import "/src/nodes.typ": node, edge

#set page(width: 16cm, height: 12cm)
#set text(font: "Noto Sans", size: 1.5em)

#let colors = (
  rgb("#4A90E2"),
  rgb("#E94E77"),
  rgb("#F5A623"),
  rgb("#FFFFFF"),
  rgb("#BBBBBB"),
).map(c => c.lighten(50%))

#let big-gap = .5
#let gap = .3
#let serv-w = ((13 - 2 * gap) / 3)

#let block(pos, lbl, ..args) = node(
  pos,
  text(size: .8em)[#lbl],
  inset: .4cm,
  radius: 2pt,
  ..args
)

#let app(pos, lbl, ..args) = block(
  pos,
  lbl,
  fill: colors.at(0),
  width: 4cm,
  height: 1.1cm,
  ..args,
)

#let serv(pos, lbl, ..args) = block(
  pos,
  lbl,
  fill: colors.at(2),
  width: serv-w,
  height: 1.2,
  ..args,
)

#let kobj(pos, lbl, ..args) = block(
  pos,
  lbl,
  fill: colors.at(3),
  width: (13 - gap * 6) / 5,
  height: 1.5cm,
  ..args,
)

#let uk-line(left, right, kernel, user) = {
  import cetz.draw: line
  let uk-left = (left + ".south-west", 50%, kernel + ".north-west")
  let uk-right = (right + ".south-east", 50%, kernel + ".north-east")
  let color = black.lighten(50%)
  line(
    (left + ".south-west", "|-", uk-left),
    ((rel: (1, 0), to: right + ".south-east"), "|-", uk-right),
    stroke: color,
  )
  node((east-of: (kernel, gap)), text(fill: color)[kernel], body-angle: 90deg, stroke: 0pt)
  node((east-of: (user, gap)), text(fill: color)[user], body-angle: 90deg, stroke: 0pt)
}

#cetz.canvas({
  block((0, 0), [Hardware], fill: colors.at(4), width: 13cm, name: "hw")
  block(
    (north-of: ("hw", big-gap)),
    [Fiasco.OC Microkernel],
    body-pos: "north",
    fill: colors.at(1),
    width: 13cm, height: 3cm,
    name: "kernel"
  )

  kobj((in-south-west: ("kernel", gap)), [Task], name: "task")
  kobj((east-of: ("task", gap)), [Thread], name: "thread")
  kobj((east-of: ("thread", gap)), [IPC], name: "ipc")
  kobj((east-of: ("ipc", gap)), [IRQ], name: "irq")
  kobj((in-south-east: ("kernel", gap)), [Sched], name: "sched")

  serv((north-of: ("kernel", big-gap * 2)), [L4Re], width: 13cm, name: "l4re")
  serv((north-of: ("l4re", gap, "left")), [L4Linux], name: "l4linux")
  serv((east-of: ("l4linux", gap)), [Dope], name: "dope")
  serv((east-of: ("dope", gap)), [VPFS], name: "vpfs")

  app((north-of: ("l4linux", gap)), [Lx Application], width: serv-w, name: "lxapp")
  app(
    (north-of: ("dope", gap, "left")),
    [L4Re Application],
    width: serv-w * 2 + gap,
    name: "l4reapp",
  )

  uk-line("l4re", "l4re", "kernel", "l4re")
})
