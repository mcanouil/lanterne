// Detection is generic and total: a marker is found inside any element,
// registered or not, so it can never be silently dropped.
//
// fields() is readable on every element (see docs/notes/roundtrip-findings.md),
// and field values can be content, arrays of content, or arrays of arrays.
// The traversal has to recurse into all of those shapes, not just a flat
// array of content, or a marker buried in a container field goes unseen.

#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/walk.typ": has-marker

#let m = marker(MARKER-PAUSE)

#assert(has-marker(m))
#assert(has-marker([before #m after]))
#assert(has-marker(block[#m]))
#assert(has-marker(block(box(block[#m]))))
#assert(has-marker(list([a], [b #m])))
#assert(has-marker(grid(columns: 2, [a], [#m])))
#assert(has-marker(figure(caption: [c])[#m]))

// text(size: ..)[..] produces a styled element wrapping a text element, not
// a text element itself, so a marker inside it is two levels down.
#assert(has-marker(text(size: 12pt)[#m]))

// [*a* b] is a genuine sequence: adjacent text merges, so [a b] would not be.
#assert(has-marker([*a* #m]))

// A matrix holds an array of arrays of content, which is the shape the flat
// `node.any(has-marker)` shortcut would miss. A grid's children are flat.
#assert(has-marker($mat(1, #m; 3, 4)$))
#assert(not has-marker($mat(1, 2; 3, 4)$))

// A context block reports no fields until layout, so a marker inside one is
// invisible to the walk. Pinned so the limitation is a decision, not a
// surprise; see the module header.
#assert(not has-marker(context [#m]))

#assert(not has-marker([plain text]))
#assert(not has-marker(block[nothing here]))
#assert(not has-marker(block(box(block[still nothing]))))
#assert(not has-marker(metadata((tag: "other"))))
#assert(not has-marker([*a* b]))

// ---------------------------------------------------------------------------
// Depth. See docs/notes/depth-limits.md for the measurements behind MAX-DEPTH.
// ---------------------------------------------------------------------------

#let nest(k, every) = {
  let acc = m
  for _ in range(k) { acc = if every { block(acc + m) } else { block(acc) } }
  acc
}

// A marker at every level is the case the guard used to miss entirely:
// detection short-circuits on the first one it meets, so the counter never
// climbed and the rebuild that followed died inside Typst instead.
#assert(has-marker(nest(9, true)))
#assert(has-marker(nest(19, false)))

// The shape generated content actually reaches: a two column grid holding a
// callout, itself three blocks deep, with a nested list and #strong inside
// #emph. Measured at 14 of the 20 levels allowed.
#assert(has-marker(grid(
  columns: (1fr, 1fr),
  block(fill: rgb("#dae6fb"), block(inset: 8pt, block(fill: white, inset: 8pt)[
    #list([One.], [Two. #emph[deep #strong[deeper #m]]])
  ])),
  [b],
)))

// max-depth is the escape hatch, and it works in both directions.
#assert(has-marker(nest(30, false), max-depth: 40))
#assert(has-marker(block[#m], max-depth: 1))

// The failing half cannot be asserted, because Typst cannot catch a panic.
// Compiled by hand, `has-marker(nest(30, false))` reports
//
//   error: panicked with: walk: content is nested more than 20 levels deep.
//   Flatten the nesting on this slide, or raise max-depth.
//
// which is the message the bare Typst diagnostic used to replace.

walk detection tests passed.
