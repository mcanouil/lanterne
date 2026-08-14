// One splitter, two predicates: headings give slides, markers give steps.

#import "../../src/core/marker.typ": MARKER-PAUSE, is-marker, marker
#import "../../src/core/split.typ": split-on
#import "../../src/core/walk.typ": has-marker

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

// A set or show rule wraps everything it governs in a `styled` element, so
// the boundaries after it sit inside that wrapper rather than beside it.
// This is the shape a deck actually receives: `#show: deck.with(...)` hands
// the function a styled element whenever the document sets anything after it.
#let STYLED = text(size: 12pt)[x].func()

#let set-body = [#set text(size: 10pt)
a #m b #m c]
#assert.eq(split-on(set-body, is-marker).len(), 3)
#assert(split-on(set-body, is-marker).all(seg => not has-marker(seg)))

// The style survives the split: every child comes back wrapped as it was
// found. Equality against a hand-built expected value is not asserted,
// because the rebuilt segment wraps each child while the original wraps the
// whole sequence once, and the two are unequal as content while rendering
// the same.
#assert(split-on(set-body, is-marker).first().children.all(c => c.func() == STYLED))

// An element show rule produces the same wrapper.
#assert.eq(
  split-on(
    [#show strong: it => it
      a #m b],
    is-marker,
  ).len(),
  2,
)
#assert.eq(
  split-on(
    [#show heading: it => it
      intro
      == A
      body],
    is-h2,
  ).len(),
  2,
)

// Consecutive rules merge into one wrapper rather than nesting, but the
// splitter must not depend on that.
#assert.eq(
  split-on(
    [#set text(size: 10pt)
      #set par(leading: 1em)
      a #m b],
    is-marker,
  ).len(),
  2,
)

// A rule governing a single element, with no sequence beneath it.
#assert.eq(
  split-on(
    [#set text(size: 10pt)
      #m],
    is-marker,
  ).len(),
  2,
)

// A rule reached part way through the body: the wrapper is one child among
// several, and the boundaries on both sides of it must be found.
#assert.eq(
  split-on(
    [x #m y
      #set text(size: 10pt)
      a #m b],
    is-marker,
  ).len(),
  3,
)

// Rules nest, and the styles are re-applied in the order they were peeled.
// A content block that opens with a rule is a styled element like any other,
// so the splitter looks through it and a marker inside it does produce a
// boundary. The same block without a rule is a plain nested sequence and does
// not. Nothing in the content distinguishes the two shapes, so this asymmetry
// is pinned rather than resolved.
#let nested-rule = [#set text(size: 10pt)
a #[#set par(leading: 1em)
b #m c] d]
#assert.eq(split-on(nested-rule, is-marker).len(), 2)
#assert.eq(split-on([a #[b #m c] d], is-marker).len(), 1)

// `#show: doc => f(doc)` is not this case. It is applied where it is written,
// so the body becomes whatever `f` returned, and a container is a container.
// The documented rule that only direct children are examined covers it.
#assert.eq(
  split-on(
    [#show: doc => block(doc)
      intro
      == A
      body],
    is-h2,
  ).len(),
  1,
)

split tests passed.
