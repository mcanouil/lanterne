// Reconstruction: registry first, hard error last.
//
// The rule is stated in notes/roundtrip-findings.md and its data lives in
// src/core/registry.typ. Fields named positionally there are handed back as
// positional arguments, in declaration order, and the rest by name.
//
// Two traps govern how the assertions below are written.
//
// Content equality ignores labels, so an equality assertion cannot detect a
// rebuild that drops one. The label assertions read the label itself.
//
// Typst memoises a call, so two calls at the same call site with the same
// arguments hand back the same instance. An equality assertion routed through
// a helper compares two calls sharing that helper's call site and proves
// nothing. Every assertion below is written inline.

#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/registry.typ": register-container
#import "../../src/core/walk.typ": rebuild

#let m = marker(MARKER-PAUSE)
#let drop = node => []
#let keep = node => node
#let sub = node => [z]

// ---------------------------------------------------------------------------
// A subtree with no marker is returned untouched, whatever its type.
// ---------------------------------------------------------------------------

#assert.eq(rebuild(block[plain], drop), block[plain])
#assert.eq(rebuild([plain text], drop), [plain text])
#assert.eq(rebuild(table([a], [b]), drop), table([a], [b]))
#assert.eq(rebuild(1em, drop), 1em)

// A marker-free sibling of a marker is handed back rather than rebuilt, which
// is what keeps an unregistered element from failing when nothing under it
// carries a boundary. `outline` is unregistered and holds content in a field,
// which tests/unit/test-registry.typ pins.
#assert.eq(rebuild([#m #outline(title: [t])], keep), [#m #outline(title: [t])])
#assert.eq(
  rebuild(block[#m #outline(title: [t])], sub),
  block[z #outline(title: [t])],
)

// ---------------------------------------------------------------------------
// A marker is replaced by whatever the transform returns, at any depth, and
// the transform receives the marker itself rather than its container.
// ---------------------------------------------------------------------------

#assert.eq(rebuild(m, drop), [])
#assert.eq(rebuild(block[#m], drop), block[])
#assert.eq(rebuild(block(box(block[#m])), drop), block(box(block[])))
#assert.eq(rebuild(block[#m], node => [#node.value.kind]), block[pause])

// The container survives with its named fields intact.
#assert.eq(
  rebuild(block(width: 1cm, fill: red)[#m], drop),
  block(width: 1cm, fill: red)[],
)

// Reconstruction is faithful: with the identity transform the tree that comes
// back equals the tree that went in, marker included.
#assert.eq(rebuild(block(width: 1cm)[a #m b], keep), block(width: 1cm)[a #m b])

// ---------------------------------------------------------------------------
// One case per registry shape.
//
// Each assertion substitutes the marker rather than keeping it, so it holds
// only if the traversal reached the marker and put the element back together
// with every one of its other fields.
// ---------------------------------------------------------------------------

// A single positional body.
#assert.eq(rebuild(heading(level: 2)[#m], sub), heading(level: 2)[z])

// Two positional fields, handed back in declaration order.
#assert.eq(rebuild(align(center)[#m], sub), align(center)[z])
#assert.eq(rebuild(columns(2)[#m], sub), columns(2)[z])

// An optional leading positional is absent from fields() when it was never
// set, and must not be filled from the field that follows it.
#assert.eq(rebuild(align[#m], sub), align[z])

// A variadic container spreads its children into separate arguments.
#assert.eq(rebuild(grid(columns: 2, [a], [#m]), sub), grid(columns: 2, [a], [z]))
#assert.eq(rebuild(list([a], [#m]), sub), list([a], [z]))

// A sequence looks like a container and is not one: its children array is a
// single positional argument. Adjacent text merges, so [a b] is one text
// element and a genuine sequence needs mixed content.
#assert.eq(rebuild([*a* #m], sub), [*a* z])

// The field name and the parameter name differ: `dest` against `destination`.
// Passing the value positionally is what makes the mismatch irrelevant.
#assert.eq(
  rebuild(link("https://example.com")[#m], sub),
  link("https://example.com")[z],
)

// Setting a text property yields a styled element wrapping a text element,
// with two positional fields of which one is not content.
#assert.eq(rebuild(text(size: 12pt)[#m], sub), text(size: 12pt)[z])

// A marker in a named field is rebuilt too, not just one in a positional.
#assert.eq(rebuild(figure(caption: [#m])[body], sub), figure(caption: [z])[body])

// A marker inside a dictionary field is reached and replaced, and the keys
// beside it come back untouched. Detection that found a marker reconstruction
// could not reach would turn a silent loss into a crash inside Typst.
#assert.eq(rebuild(metadata((a: m, b: 1)), sub), metadata((a: [z], b: 1)))
#assert.eq(rebuild(metadata((a: (b: m))), drop), metadata((a: (b: []))))
#assert.eq(rebuild(metadata((a: (m,))), drop), metadata((a: ([],))))
#assert.eq(rebuild(metadata((a: 1)), drop), metadata((a: 1)))

// ---------------------------------------------------------------------------
// An element with no registry entry that carries a marker is a hard error,
// which cannot be asserted because a panic aborts compilation. The remedy the
// message names is asserted instead: a registration threaded into the call
// makes the same tree rebuild. outline.entry is absent from the built in set.
// ---------------------------------------------------------------------------

#let extended = register-container(outline.entry, ("level", "element"))

#assert.eq(
  rebuild(outline.entry(1, [#m]), sub, registry: extended),
  outline.entry(1, [z]),
)

// ---------------------------------------------------------------------------
// Labels survive a rebuild.
//
// `label` appears in fields() but is not a constructor parameter, so it has to
// be stripped before the fields are spread and reattached afterwards. Content
// equality ignores labels, so the assertions that matter here read the label.
// ---------------------------------------------------------------------------

#let labelled = [#block[#m] <lbl>].children.first()
#assert.eq(labelled.label, <lbl>)

#let relabelled = rebuild(labelled, drop)
#assert.eq(relabelled.func(), block)
#assert.eq(relabelled.label, <lbl>)

// Reattachment preserves the element rather than wrapping it in a sequence,
// and equality alone would have passed even with the label dropped.
#assert.eq(relabelled, block[])

// A label nested inside a rebuilt container survives as well.
#let nested = rebuild(block[#box[#m] <inner>], drop)
#assert.eq(nested.body.children.first().label, <inner>)

// ---------------------------------------------------------------------------
// An image is an opaque leaf.
//
// Image equality is instance identity rather than field equality, so any
// reconstruction of an image is unequal to the original however faithful its
// fields are. The traversal returns the instance it was given.
// ---------------------------------------------------------------------------

#let svg-bytes = bytes(
  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1\" height=\"1\"></svg>",
)
#let img = image(svg-bytes, format: "svg")

#assert.eq(rebuild(img, drop), img)

// The instance comes back even when its parent is rebuilt around it.
#assert.eq(rebuild(block[#img#m], keep).body.children.first(), img)

// ---------------------------------------------------------------------------
// Synthesised fields.
//
// Inside a show rule an element carries fields that are not constructor
// parameters. A figure gains `counter`, which must be dropped, while `scope`
// must be kept: dropping it produces a rebuild that no longer compares equal.
// The show rule returns nothing so that the rebuilt figure is never shown,
// which would re-enter the rule.
// ---------------------------------------------------------------------------

#show figure: it => {
  assert("counter" in it.fields())
  assert.eq(rebuild(it, keep), it)
  []
}

#figure(caption: [c])[body #m]

// A marker in the caption rather than the body reaches figure.caption, which
// synthesises four fields that are not constructor parameters.
#figure(caption: [c #m])[body]

#show figure.caption: it => {
  assert("kind" in it.fields())
  assert.eq(rebuild(it, keep), it)
  []
}

#figure(caption: [c #m])[body]

// An explicitly numbered item carries `number`, which is positional-only.
#assert.eq(rebuild(enum.item(3)[a #m], keep), enum.item(3)[a #m])
#assert.eq(rebuild([3. a #m], keep), [3. a #m])

// ---------------------------------------------------------------------------
// Depth. See notes/depth-limits.md for the measurements behind MAX-DEPTH.
// ---------------------------------------------------------------------------

#let nest(k, every) = {
  let acc = m
  for _ in range(k) { acc = if every { block(acc + m) } else { block(acc) } }
  acc
}

// A marker at every level, nested to just under the default. This is the case
// that used to reach Typst's own recursion limit: the guard's counter was
// driven by a detection walk that short-circuits on the first marker, and it
// restarted from zero at every level of the rebuild besides.
#assert.eq(rebuild(nest(9, true), keep), nest(9, true))
#assert.eq(rebuild(nest(19, false), keep), nest(19, false))

// The marker reached first at every level, which is the exact shape the old
// guard passed straight through: detection returned true before its counter
// left zero, so nothing bounded the rebuild and 20 levels of this died with
// Typst's own `maximum function call depth exceeded` and no source location.
#let nest-first(k) = {
  let acc = m
  for _ in range(k) { acc = block(m + acc) }
  acc
}
#assert.eq(rebuild(nest-first(9), keep), nest-first(9))

// A deep subtree holding no marker is never reconstructed, but it is still
// walked to find that out, so the budget bounds it too. 25 levels of it
// beside a marker is content Typst handles and the walk must not reject.
#let free(k) = {
  let acc = [leaf]
  for _ in range(k) { acc = block(acc) }
  acc
}
#assert.eq(rebuild([#m #free(25)], keep), [#m #free(25)])

// max-depth raises the ceiling for content that needs it.
#assert.eq(rebuild(nest(30, false), keep, max-depth: 36), nest(30, false))

// The failing half cannot be asserted, because Typst cannot catch a panic. It
// is compiled as its own file instead: tests/expect-fail/walk-depth-rebuild.typ
// pins the message, alongside walk-unregistered-element.typ, which pins the
// panic that keeps a marker from being silently lost.
//
// One case stays a comment because it is Typst's behaviour rather than this
// package's. `rebuild(nest(30, true), keep, max-depth: 100000)`, which lifts
// the guard entirely, reports Typst's own
//
//   error: maximum function call depth exceeded
//
// with no source location. That is the ceiling no guard can raise, and why
// the default sits below it rather than at it.

walk rebuild tests passed.
