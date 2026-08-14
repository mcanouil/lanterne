// One splitter, two predicates: headings give slides, markers give steps.

#import "../../src/core/marker.typ": MARKER-PAUSE, is-marker, marker
#import "../../src/core/split.typ": split-on

#let m = marker(MARKER-PAUSE)

// No match: one segment containing everything.
#assert.eq(split-on([a b], is-marker).len(), 1)

// One match: two segments, the marker itself dropped.
#assert.eq(split-on([a #m b], is-marker).len(), 2)

// Leading match: an empty first segment, not a dropped one.
#assert.eq(split-on([#m a], is-marker).len(), 2)

// Trailing match: an empty last segment.
#assert.eq(split-on([a #m], is-marker).len(), 2)

// Consecutive matches produce an empty segment between them.
#assert.eq(split-on([a #m #m b], is-marker).len(), 3)

// A non-sequence body is a single segment.
#assert.eq(split-on([solo], is-marker).len(), 1)

// Segment contents, not just their count. A length assertion alone passes
// even when the splitter has taken a container apart.
// The whitespace either side of a marker belongs to the adjacent segments,
// so the expected segments are built by concatenation rather than markup.
#assert.eq(split-on([a #m b], is-marker), ([a] + [ ], [ ] + [b]))
#assert.eq(split-on([#m a], is-marker), ([], [ ] + [a]))
#assert.eq(split-on([a #m], is-marker), ([a] + [ ], []))

// A container has a `children` field but is not a sequence, and must come
// back whole rather than as its cells.
#assert.eq(split-on(grid(columns: 2, [a], [b]), is-marker), (grid(columns: 2, [a], [b]),))
#assert.eq(split-on(list([a], [b]), is-marker), (list([a], [b]),))
#assert.eq(split-on(table([a]), is-marker), (table([a]),))
#assert.eq(split-on(stack([a]), is-marker), (stack([a]),))
#assert.eq(split-on(enum([a]), is-marker), (enum([a]),))

// Only direct children are examined, so a nested match produces no boundary.
// Pinned so the limitation is a decision, not a surprise.
#assert.eq(split-on([a #block[#m] b], is-marker).len(), 1)

// Heading predicate, the other caller. `heading(level: 2)[A]` carries `level`,
// while the markup form `== A` carries `depth`, so a predicate reading either
// name alone fails with `field "..." in heading is not known at this point` on
// half the decks it meets.
#let is-h2 = node => {
  if type(node) != content or node.func() != heading { return false }
  let fields = node.fields()
  fields.at("depth", default: fields.at("level", default: none)) == 2
}
#assert.eq(split-on([intro #heading(level: 2)[A] body], is-h2).len(), 2)
#assert.eq(split-on([intro
== A
body], is-h2).len(), 2)

split tests passed.
