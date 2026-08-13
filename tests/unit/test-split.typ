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

// Heading predicate, the other caller.
#let is-h2 = node => (
  type(node) == content and node.func() == heading and node.level == 2
)
#assert.eq(split-on([intro #heading(level: 2)[A] body], is-h2).len(), 2)

split tests passed.
