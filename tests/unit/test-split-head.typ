// `split-head` takes the first child a predicate matches out of a body, and
// hands back both halves inside the style wrappers they were found under.
//
// It exists for one caller that does not exist yet: a theme's header slot wants
// a slide's title as a value it can place, and the title is the heading the
// author wrote. Lifting that heading out of its wrappers loses its numbering,
// the document's own `show heading` rule and the destination a reference
// resolves to, which is the failure ARCHITECTURE records under "The slide's
// title stays where it was written". Both halves keep their wrappers, so the
// rules in force over the title still reach it wherever it is placed.
//
// Typst cannot catch a panic, so the rejecting paths are compiled as their own
// files under tests/expect-fail/.

#import "../../src/core/split.typ": is-blank, split-head
#import "../../src/core/walk.typ": collect, has-element
#import "../../src/utils/elements.typ": STYLED, is-elem

#let label-of(node) = node.fields().at("label", default: none)

// The shape of a body a deck actually receives: a rule written after
// `#show: deck.with(...)` wraps everything that follows it.
#let wrapped = [
  #set heading(outlined: false)
  == A title <split-head-title>

  Body text, and a #box[boxed] word.
]
#let cut = split-head(wrapped, node => is-elem(node, heading))

#assert(cut.found)

// The heading is in the head and nowhere else.
#assert(has-element(cut.head, heading))
#assert(not has-element(cut.rest, heading))

// The body of the slide is in the rest and nowhere else.
#assert(has-element(cut.rest, box))
#assert(not has-element(cut.head, box))

// Both halves carry the wrapper rather than losing it, which is the whole
// point. The head is the wrapper itself, since the heading sat directly under
// it; the rest carries it nested, because the body's own children sit around
// it. What matters is that each half is governed by it, not where it sits.
#assert(is-elem(cut.head, STYLED))
#assert(has-element(cut.rest, STYLED))

// A predicate matches the first child that satisfies it, not the first child.
// A body opening with a space or a paragraph break still finds its heading.
#let led = [

  == Led

  tail
]
#assert(split-head(led, node => is-elem(node, heading)).found)

// Only the first match moves. A heading written inside a slide is content, and
// the caller's predicate is what decides which one is the title.
#let two = [
  == Title

  === Inner

  tail
]
#let by-level = split-head(two, node => is-elem(node, heading) and node.depth == 2)
#assert(by-level.found)
#assert(has-element(by-level.rest, heading))

// With no match the body comes back as it went in, rather than rebuilt, and
// nothing is claimed to have been found.
#let plain = [no heading here]
#let missed = split-head(plain, node => is-elem(node, heading))
#assert(not missed.found)
#assert.eq(missed.head, [])
#assert.eq(missed.rest, plain)

// A body that is nothing but its title leaves a blank rest, which is a
// legitimate slide: specification 4.1 emits one for a heading with nothing
// under it.
#let bare = [
  == Only a title
]
#let alone = split-head(bare, node => is-elem(node, heading))
#assert(alone.found)
#assert(has-element(alone.head, heading))

// A label written on a group marks the slide's content, so it stays with the
// rest rather than travelling with the title that is being moved away from it.
#let group = [#[#set heading(outlined: false)
== Titled

body] <split-head-group>]
#let cut-group = split-head(group, node => is-elem(node, heading))
#assert(cut-group.found)
#cut-group.rest
#context assert.eq(query(<split-head-group>).len(), 1)

// Unless the rest carries nothing. A title-only slide is legitimate, and a
// label on nothing at all is a reference resolving to a page showing nothing,
// which `_relabel` refuses rather than degrades. It falls to the head instead.
#let group-alone = [#[#set heading(outlined: false)
== Titled only] <split-head-alone>]
#let cut-alone = split-head(group-alone, node => is-elem(node, heading))
#assert(cut-alone.found)
#assert(is-blank(cut-alone.rest))
#cut-alone.head
#context assert.eq(query(<split-head-alone>).len(), 1)

// A group carrying no rule at all is a sequence rather than a wrapper, and it
// takes the other branch of the walk. Without a case here that branch has no
// coverage, which is the reason tests/unit/test-split.typ carries the same pair
// for `split-on`.
//
// Within the rest the label goes on the first node that carries something, not
// on the last. Markup attaches a label to the last element of what it follows,
// and the last element of a divided group is usually the space that separated
// it from what came next: such a label is dropped once the spaces around a
// boundary are merged, and the deck then fails on a reference to a label that
// no longer exists.
#let plain-group = [x #[== T

body] <split-head-plain> y]
#let cut-plain = split-head(plain-group, node => is-elem(node, heading))
#assert(cut-plain.found)
#let marked = collect(
  cut-plain.rest,
  node => type(node) == content and label-of(node) == <split-head-plain>,
)
#assert.eq(marked.len(), 1)
#assert(not is-blank(marked.first()))

// The rules the wrappers carry reach the head after it has been moved. The
// heading below is rendered out of the position it was written in, and the
// `set heading(outlined: false)` written above it still governs it.
#cut.head
// Asserted on the element itself rather than on the first heading in the
// document: several halves are rendered above, so `query(heading).first()`
// would pin whichever came first rather than this one.
#context assert.eq(query(<split-head-title>).first().outlined, false)

// The label written on the heading travels with it, so a reference to a slide
// resolves to wherever its title was placed.
#context assert.eq(query(<split-head-title>).len(), 1)

split-head tests passed.
