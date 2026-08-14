// One splitter, two predicates: headings give slides, markers give steps.

#import "../../src/core/marker.typ": MARKER-PAUSE, is-marker, marker
#import "../../src/core/split.typ": split-at, split-on
#import "../../src/core/walk.typ": has-marker
#import "../../src/utils/elements.typ": STYLED

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
#let set-body = [#set text(size: 10pt)
a #m b #m c]
#assert.eq(split-on(set-body, is-marker).len(), 3)
#assert(split-on(set-body, is-marker).all(seg => not has-marker(seg)))

// The style survives the split, and the segment still carries the wrapper.
#assert.eq(split-on(set-body, is-marker).first().func(), STYLED)

// A body with no boundary in it comes back exactly as it went in.
//
// This is the assertion that a segment count cannot make. Re-applying the
// styles to each child separately preserves every count in this file while
// opening a page group per child, so a `#set page` body that rendered on one
// page comes back rendering on as many pages as it has children. Identity is
// what rules that out.
#assert.eq(split-on(set-body, _ => false).first(), set-body)

#let page-body = [#set page(fill: rgb("#eeeeff"))
A

B

C]
#assert.eq(split-on(page-body, _ => false).first(), page-body)

// The same, with a second rule written part way through. The outer rule is
// still in force over the whole body, so it must go back on once rather than
// once per stretch of children between the nested wrappers. Applying it twice
// opens a second page group and the body renders on two pages.
#let two-rule-body = [#set page(fill: rgb("#eeeeff"))
A

#set text(size: 20pt)
B]
#assert.eq(split-on(two-rule-body, _ => false).first(), two-rule-body)

// A group carrying its own rule is the same shape reached another way.
#let grouped-body = [#set page(fill: rgb("#eeeeff"))
A

#[#set text(size: 20pt)
B]

C]
#assert.eq(split-on(grouped-body, _ => false).first(), grouped-body)

// An empty segment keeps the rules in force over it. A leading boundary
// otherwise yields a step with no page setup while its siblings have it.
#assert.eq(split-on([#set page(fill: rgb("#eeeeff"))
#m A], is-marker).first().func(), STYLED)

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
#let nested-rule = [#set text(size: 10pt)
a #[#set par(leading: 1em)
b #m c] d]
#assert.eq(split-on(nested-rule, is-marker).len(), 2)

// A nested sequence is looked through, whether or not it opens with a rule.
// Markup arriving as one value is exactly this shape, so a boundary inside one
// is a boundary: an `#include`, a `#let` fragment and a helper's return value
// all land as a sequence among the body's children, and a deck written across
// several files is the ordinary case.
#assert.eq(split-on([a #[b #m c] d], is-marker).len(), 2)

#let fragment = [b #m c]
#assert.eq(split-on([a #fragment d], is-marker).len(), 2)
#assert.eq(split-on([a #fragment d], is-marker), ([a] + [ ] + [b] + [ ], [ ] + [c] + [ ] + [d]))

// A container is not a sequence, so the rule stops at the elements a body is
// built from rather than descending into their contents.
#assert.eq(split-on([a #block[#m] b], is-marker).len(), 1)
#assert.eq(split-on([a #grid([#m]) b], is-marker).len(), 1)

// A label survives the split.
//
// Every other assertion in this file is an equality, and content equality
// ignores labels, so a splitter that dropped every label would satisfy all of
// them. `tests/unit/test-walk-rebuild.typ` documents the same trap for the
// rebuild. These read the field instead.
#let styled-of(node) = node.children.find(child => child.func() == STYLED)
#let label-of(node) = node.fields().at("label", default: none)

#let labelled = [x #[#set text(size: 9pt)
a b] <lbl> y]
#assert.eq(label-of(styled-of(split-on(labelled, _ => false).first())), <lbl>)

// When a boundary cuts through the labelled group, the label can only go on
// one piece: emitting it on each would make the deck fail with a duplicate
// label, which is worse than the reference landing at the end of the group.
// Specification 4.6 already rules that a labelled element behind a pause keeps
// its label on the final step, so the last piece carries it here too.
#let labelled-split = [x #[#set text(size: 9pt)
a #m b] <lbl> y]
#let split-pieces = split-on(labelled-split, is-marker)
#assert.eq(split-pieces.len(), 2)
#assert.eq(label-of(styled-of(split-pieces.first())), none)
#assert.eq(label-of(styled-of(split-pieces.last())), <lbl>)

// The same wrapper with nothing beside it. The first assertion above passes on
// its own even when the wrapper is handed back whole and unsplit, so this pins
// the shape where there is no surrounding content to hide that.
#let labelled-alone = [#[#set text(size: 9pt)
a b] <lbl>]
#assert.eq(label-of(styled-of(split-on(labelled-alone, _ => false).first())), <lbl>)

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

// ---------------------------------------------------------------------------
// The boundary that opened a segment, handed back beside it.
//
// A heading is both a boundary and the slide's title, so a splitter that only
// drops its matches cannot build a slide. `split-at` is the same walk reporting
// what it matched, which is why every assertion here also compares its bodies
// against `split-on` over the same input: the two must never disagree about
// where a segment starts and ends.
// ---------------------------------------------------------------------------

#let h2 = heading(level: 2)[A]

// The first segment is opened by the body rather than by a match, so its
// boundary is none.
#let two-headings = [intro #h2 middle #h2 tail]
#assert.eq(split-at(two-headings, is-h2).len(), 3)
#assert.eq(split-at(two-headings, is-h2).first().boundary, none)
#assert.eq(split-at(two-headings, is-h2).at(1).boundary, h2)
#assert.eq(split-at(two-headings, is-h2).last().boundary, h2)
#assert.eq(
  split-at(two-headings, is-h2).map(part => part.body),
  split-on(two-headings, is-h2),
)

// The boundary is dropped from the body it opened, exactly as `split-on` drops
// it, so a caller that re-emits the title does not emit it twice.
#assert(split-at(two-headings, is-h2).all(part => not is-h2(part.body)))

// No match at all: one part, carrying the whole body and no boundary.
#assert.eq(split-at([a b], is-h2).len(), 1)
#assert.eq(split-at([a b], is-h2).first().boundary, none)
#assert.eq(split-at([a b], is-h2).first().body, [a b])

// A leading match still opens the body with an empty first part, so a caller
// can tell content before the first heading from the absence of it.
#assert.eq(split-at([#h2 a], is-h2).len(), 2)
#assert.eq(split-at([#h2 a], is-h2).first().boundary, none)
#assert.eq(split-at([#h2 a], is-h2).first().body, [])

// A boundary found under a style wrapper is handed back unwrapped: a caller
// reads its fields rather than rendering it, and the wrapper belongs around the
// segment where the rules it carries apply.
#let styled-headings = [#set text(size: 10pt)
intro #h2 body]
#assert.eq(split-at(styled-headings, is-h2).len(), 2)
#assert.eq(split-at(styled-headings, is-h2).last().boundary, h2)
#assert.eq(split-at(styled-headings, is-h2).last().body.func(), STYLED)
#assert.eq(
  split-at(styled-headings, is-h2).map(part => part.body),
  split-on(styled-headings, is-h2),
)

// The marker predicate is the other caller, and it wants what it always
// wanted: `split-at` reports the marker, `split-on` drops it, and the segments
// are the same either way.
#assert.eq(split-at([a #m b], is-marker).at(1).boundary, m)
#assert.eq(split-at(set-body, is-marker).map(part => part.body), split-on(set-body, is-marker))

// ---------------------------------------------------------------------------
// A match left where it was found.
//
// `keep` is what a heading needs. Lifting a heading out of the wrappers it was
// written under and re-emitting it beside them loses everything those rules
// carry: the document's own numbering, its `show heading` rule and the named
// destination a reference resolves to. A match left in place keeps all three,
// because it is the same element in the same wrapper.
// ---------------------------------------------------------------------------

// The match opens the segment and stays at its head.
#let kept = split-at(two-headings, is-h2, keep: _ => true)
#assert.eq(kept.len(), 3)
#assert.eq(kept.at(1).boundary, h2)
#assert.eq(kept.at(1).body, h2 + [ ] + [middle] + [ ])

// It stays inside the wrapper rather than beside it, which is the whole point:
// the segment is still one styled element, not a heading followed by one.
#let kept-styled = split-at(styled-headings, is-h2, keep: _ => true).last()
#assert.eq(kept-styled.body.func(), STYLED)
#assert.eq(kept-styled.body.child.children.first(), h2)

// The decision is per match, so a caller splitting on several kinds of boundary
// keeps the ones it re-reads and drops the ones it consumes.
#let mixed = split-at([a #h2 b #m c], node => is-h2(node) or is-marker(node), keep: is-h2)
#assert.eq(mixed.len(), 3)
#assert.eq(mixed.at(1).body.children.first(), h2)
#assert(not mixed.at(2).body.children.any(child => child.func() == metadata))

// Keeping nothing is what `split-at` does by default, and says so twice rather
// than by omission.
#assert.eq(
  split-at(two-headings, is-h2).map(part => part.body),
  split-at(two-headings, is-h2, keep: _ => false).map(part => part.body),
)

split tests passed.
