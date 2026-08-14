// The registry records, per element function, which fields must be handed
// back positionally when that element is rebuilt.
//
// The entry set is the "Registry recommendations for Task 5" table in
// notes/roundtrip-findings.md, which is the authoritative
// characterisation. tests/unit/test-roundtrip.typ pins the recipe each
// element needs; this file pins that the registry reports that same recipe.
//
// Transcribing a table into asserts proves only that two copies of the table
// agree, so the entries are also driven through a real rebuild below. That is
// the assertion that can actually fail if an entry is wrong.
//
// Typst cannot catch a panic, so the argument validation in
// register-container and lookup is asserted on its accepting paths here. Every
// rejecting path is compiled as its own case under tests/expect-fail/, where a
// file is asserted to fail with the message it records.

#import "../../src/core/registry.typ": (
  builtin-registry, lookup, register-container,
)
#import "../../src/utils/elements.typ": SEQUENCE, STYLED

// ---------------------------------------------------------------------------
// Lookup resolves an entry for each shape in the findings table.
// ---------------------------------------------------------------------------

// A single positional `body`, the commonest shape.
#assert.eq(lookup(block), (positional: ("body",), spread: false))
#assert.eq(lookup(heading), (positional: ("body",), spread: false))
#assert.eq(lookup(list.item), (positional: ("body",), spread: false))

// list.item and enum.item share a repr, so a repr-keyed registry silently
// answers one for the other. They must resolve independently.
#assert.eq(lookup(enum.item), (positional: ("number", "body"), spread: false))
#assert.eq(lookup(table.cell), (positional: ("body",), spread: false))
#assert.eq(lookup(grid.cell), (positional: ("body",), spread: false))

// Two positional fields, in declaration order.
#assert.eq(lookup(align), (positional: ("alignment", "body"), spread: false))
#assert.eq(lookup(columns), (positional: ("count", "body"), spread: false))
#assert.eq(
  lookup(terms.item),
  (positional: ("term", "description"), spread: false),
)
#assert.eq(lookup(STYLED), (positional: ("child", "styles"), spread: false))

// The two name mismatches: the field name is not the parameter name, so the
// registry must record the field name that fields() actually returns.
#assert.eq(lookup(link), (positional: ("dest", "body"), spread: false))
#assert.eq(lookup(text), (positional: ("text",), spread: false))
#assert.eq(lookup(raw), (positional: ("text",), spread: false))

// Variadic containers spread their children array into separate arguments.
#assert.eq(lookup(list), (positional: ("children",), spread: true))
#assert.eq(lookup(grid), (positional: ("children",), spread: true))
#assert.eq(lookup(polygon), (positional: ("vertices",), spread: true))
#assert.eq(lookup(curve), (positional: ("components",), spread: true))
#assert.eq(lookup(math.mat), (positional: ("rows",), spread: true))

// The header and footer rows are containers too. Quarto emits a header for
// every Markdown table, and none of the four survive a plain spread.
// `repr` cannot tell `table.header` from `grid.header`, so both are asserted.
#assert.eq(lookup(table.header), (positional: ("children",), spread: true))
#assert.eq(lookup(table.footer), (positional: ("children",), spread: true))
#assert.eq(lookup(grid.header), (positional: ("children",), spread: true))
#assert.eq(lookup(grid.footer), (positional: ("children",), spread: true))

// `repr(footnote.entry)` and `repr(outline.entry)` are both "entry", and only
// one of them is registered, so this pair fails if the bucket stops comparing
// the function value itself.
#assert.eq(lookup(footnote.entry), (positional: ("note",), spread: false))
#assert.eq(lookup(outline.entry), none)

// A sequence takes the same field name as a container and must not spread.
#assert.eq(lookup(SEQUENCE), (positional: ("children",), spread: false))

// The whole table is present. A dropped entry is a silent rebuild panic in
// Task 7, so the count is pinned.
#let count-entries(registry) = registry.values().map(b => b.len()).sum()
#let entry-count = count-entries(builtin-registry())
#assert.eq(entry-count, 72)

// ---------------------------------------------------------------------------
// An element absent from the registry is unknown.
//
// The six elements of list 1 in the findings note reconstruct under a plain
// spread of their fields, so they are deliberately not registered. Absence
// says nothing about any other element.
// ---------------------------------------------------------------------------

#assert.eq(lookup(linebreak), none)
#assert.eq(lookup(parbreak), none)
#assert.eq(lookup(pagebreak), none)
#assert.eq(lookup(outline), none)
#assert.eq(lookup(line), none)

// ---------------------------------------------------------------------------
// The entries are correct, not merely transcribed.
//
// This is the rebuild rule of notes/roundtrip-findings.md, driven
// entirely from the registry. The shared helper it prefigures is Task 7; this
// copy exists so a wrong entry fails here rather than in the traversal.
// ---------------------------------------------------------------------------

#let rebuild-via-registry(node) = {
  let entry = lookup(node.func())
  let positional = if entry == none { () } else { entry.positional }
  let spread = if entry == none { false } else { entry.spread }
  let fields = node.fields()
  let named = fields
  for key in positional {
    let _ = named.remove(key, default: none)
  }
  // An unset optional positional parameter is absent from fields(), so a
  // listed key the instance does not carry is skipped rather than indexed.
  let values = positional.filter(key => key in fields).map(key => fields.at(key))
  if spread {
    (node.func())(..named, ..values.first())
  } else {
    (node.func())(..named, ..values)
  }
}

#let round-trips(node) = rebuild-via-registry(node) == node

#assert(round-trips(block[hello]))
#assert(round-trips(heading(level: 2)[Title]))
#assert(round-trips(list.item[a]))
#assert(round-trips(enum.item[a]))
#assert(round-trips(table.cell[c]))
#assert(round-trips(grid.cell[c]))
#assert(round-trips(align(center)[x]))
#assert(round-trips(columns(2)[x]))
#assert(round-trips(terms.item([a], [b])))
#assert(round-trips(text(size: 12pt)[hello]))
#assert(round-trips(link("https://example.com")[x]))
#assert(round-trips([hello]))
#assert(round-trips(raw("code")))
#assert(round-trips(list([a], [b])))
#assert(round-trips(grid([a], [b])))
#assert(round-trips(polygon((0pt, 0pt), (1cm, 0pt), (0pt, 1cm))))
#assert(round-trips(curve(curve.line((1cm, 1cm)))))
#assert(round-trips($mat(1, 2; 3, 4)$.body))
#assert(round-trips([*a* b]))
#assert(round-trips($x + 1$))
#assert(round-trips(metadata((a: 1))))
#assert(round-trips(h(1em)))
#assert(round-trips(ref(<lbl>)))
#assert(round-trips(cite(<key>)))

// The unregistered six go through the same path with an empty positional
// list, which is the plain spread they already survive.
#assert(round-trips(linebreak()))
#assert(round-trips(parbreak()))
#assert(round-trips(line(length: 1cm)))
#assert(round-trips(outline()))

// Instances that leave an optional positional parameter unset. The key is
// absent from fields() entirely, so an entry that indexed it would panic.
#assert(round-trips(block(width: 1cm)))
#assert(round-trips(box(width: 1fr)))
#assert(round-trips(rect(width: 1cm, height: 1cm)))
#assert(round-trips(circle(radius: 1cm)))
#assert(round-trips(square(size: 1cm)))
#assert(round-trips(ellipse(width: 2cm)))
#assert(round-trips(place(dx: 1cm, dy: 1cm)[x]))
#assert(round-trips(columns[x]))
#assert(round-trips(enum.item(3)[a]))

// Transforms, maths and the header and footer containers. None of these
// survive the plain spread, so an unregistered element cannot be assumed
// to have no positional fields.
#assert(round-trips(rotate(45deg)[x]))
#assert(round-trips(scale(50%)[x]))
#assert(round-trips(move(dx: 1pt)[x]))
#assert(round-trips(skew(ax: 10deg)[x]))
#assert(round-trips(math.frac($1$, $2$)))
#assert(round-trips(math.vec($1$, $2$)))
#assert(round-trips(math.cases($1$, $2$)))
#assert(round-trips(math.lr($(x)$)))
#assert(round-trips(math.attach($x$, t: $2$)))
#assert(round-trips(math.accent($x$, math.hat)))
#assert(round-trips(math.root($2$, $x$)))
#assert(round-trips(math.op("lim")))
#assert(round-trips(math.class("normal", $x$)))
#assert(round-trips(math.underbrace($x$, $y$)))
#assert(round-trips(math.mid($|$)))
#assert(round-trips(table.header([a], [b])))
#assert(round-trips(table.footer([a])))
#assert(round-trips(grid.header([a])))
#assert(round-trips(grid.footer([a])))
#assert(round-trips(footnote.entry(footnote[x])))

// ---------------------------------------------------------------------------
// Registration is a value, not document state.
//
// register-container returns a new registry rather than updating a `state`,
// so lookup stays callable outside `context` and the answer does not depend
// on where in the document the registration appears. See ARCHITECTURE.md.
// ---------------------------------------------------------------------------

#let custom = register-container(linebreak, ("body",))

// The registration is visible immediately, with no context and no layout.
#assert.eq(
  lookup(linebreak, registry: custom),
  (positional: ("body",), spread: false),
)

// It is additive: the built in entries survive alongside it.
#assert.eq(
  lookup(block, registry: custom),
  (positional: ("body",), spread: false),
)
#assert.eq(entry-count + 1, count-entries(custom))

// The built in registry is untouched by the registration.
#assert.eq(lookup(linebreak), none)

// Registrations chain, and a later one overrides an earlier one for the same
// element rather than accumulating a duplicate.
#let chained = register-container(
  pagebreak,
  ("children",),
  spread: true,
  registry: custom,
)
#assert.eq(
  lookup(pagebreak, registry: chained),
  (positional: ("children",), spread: true),
)
#assert.eq(
  lookup(linebreak, registry: chained),
  (positional: ("body",), spread: false),
)

#let overridden = register-container(block, ("value",), registry: chained)
#assert.eq(
  lookup(block, registry: overridden),
  (positional: ("value",), spread: false),
)
#assert.eq(
  count-entries(overridden),
  count-entries(chained),
)

// Overriding one member of a colliding repr bucket leaves the other alone.
#let bucket-override = register-container(enum.item, ("value",))
#assert.eq(
  lookup(enum.item, registry: bucket-override),
  (positional: ("value",), spread: false),
)
#assert.eq(
  lookup(list.item, registry: bucket-override),
  (positional: ("body",), spread: false),
)

// Registering with no positional fields is legitimate and is how a user marks
// an element that the plain spread already reconstructs.
#assert.eq(lookup(block, registry: register-container(block, ())), (
  positional: (),
  spread: false,
))

// A threaded registry gives the same answer inside a context block as outside
// it, which a state based registry could not guarantee.
#context {
  assert.eq(
    lookup(linebreak, registry: custom),
    (positional: ("body",), spread: false),
  )
  assert.eq(lookup(SEQUENCE), (positional: ("children",), spread: false))
}

registry tests passed.
