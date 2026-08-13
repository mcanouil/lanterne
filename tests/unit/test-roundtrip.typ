// Characterisation: which elements survive (node.func())(..node.fields())?
//
// The full findings, including the verbatim Typst error for every failing
// element, are in docs/notes/roundtrip-findings.md. Read that file before
// changing anything here.
//
// This file is a regression guard. When it fails after a Typst upgrade, the
// registry in src/core/registry.typ needs revisiting.
//
// Typst cannot catch a panic, and 53 of the 59 probed elements make the
// generic rebuild panic rather than return an unequal value. A panic aborts
// compilation, so those cases cannot be asserted at all and are recorded in
// the findings note instead. What is asserted below is the positional rebuild
// recipe each of them needs, which is the contract Task 5 implements.

// The generic mechanism: spread every field back as a named argument.
#let round-trips(node) = (node.func())(..node.fields()) == node

// The corrected mechanism: fields named in `positional` are passed as
// positional arguments, in order, after the remaining fields are passed as
// named arguments. With `spread: true` the single positional field holds an
// array that is itself spread, which is how variadic containers are rebuilt.
#let rebuild(node, positional: (), spread: false) = {
  let fields = node.fields()
  let named = fields
  for key in positional {
    let _ = named.remove(key, default: none)
  }
  let values = positional.map(key => fields.at(key))
  if spread {
    (node.func())(..named, ..values.first())
  } else {
    (node.func())(..named, ..values)
  }
}

#let rebuilds(node, positional: (), spread: false) = {
  rebuild(node, positional: positional, spread: spread) == node
}

// ---------------------------------------------------------------------------
// Elements the generic mechanism reconstructs correctly.
//
// Every one of them has a field set drawn entirely from named parameters. If
// one of these starts failing, the generic default in the traversal is no
// longer safe for it and it needs a registry entry.
// ---------------------------------------------------------------------------

#assert(round-trips([ ]))
#assert(round-trips(linebreak()))
#assert(round-trips(parbreak()))
#assert(round-trips(pagebreak()))
#assert(round-trips(line(length: 1cm)))
#assert(round-trips(outline()))

// Failure is a property of the fields that are set, not of the element type.
// A block with no body set carries only named fields and round trips, while
// the same element with a body does not.
#assert(round-trips(block(width: 1cm)))
#assert(round-trips(box(height: 1em)))
#assert(round-trips(outline(title: [T])))

// ---------------------------------------------------------------------------
// Elements the generic mechanism cannot reconstruct.
//
// Each entry below records the positional fields that must be handed back
// positionally. The assertion is the registry contract: if one of these
// starts failing, the corresponding registry entry is wrong.
// ---------------------------------------------------------------------------

// A single positional body.
#assert(rebuilds(block[hello], positional: ("body",)))
#assert(rebuilds(box[hello], positional: ("body",)))
#assert(rebuilds(heading(level: 2)[Title], positional: ("body",)))
#assert(rebuilds(emph[x], positional: ("body",)))
#assert(rebuilds(strong[x], positional: ("body",)))
#assert(rebuilds(figure(caption: [c])[body], positional: ("body",)))
#assert(rebuilds(list.item[a], positional: ("body",)))
#assert(rebuilds(enum.item[a], positional: ("body",)))
#assert(rebuilds(footnote[x], positional: ("body",)))
#assert(rebuilds(par[x], positional: ("body",)))
#assert(rebuilds(quote[x], positional: ("body",)))
#assert(rebuilds($x + 1$, positional: ("body",)))
#assert(rebuilds(rect[x], positional: ("body",)))
#assert(rebuilds(circle[x], positional: ("body",)))
#assert(rebuilds(ellipse[x], positional: ("body",)))
#assert(rebuilds(square[x], positional: ("body",)))
#assert(rebuilds(pad(1em)[x], positional: ("body",)))
#assert(rebuilds(hide[x], positional: ("body",)))
#assert(rebuilds(underline[x], positional: ("body",)))
#assert(rebuilds(overline[x], positional: ("body",)))
#assert(rebuilds(strike[x], positional: ("body",)))
#assert(rebuilds(highlight[x], positional: ("body",)))
#assert(rebuilds(smallcaps[x], positional: ("body",)))
#assert(rebuilds(sub[x], positional: ("body",)))
#assert(rebuilds(super[x], positional: ("body",)))
#assert(rebuilds(repeat[.], positional: ("body",)))
#assert(rebuilds(figure.caption[c], positional: ("body",)))
#assert(rebuilds(table.cell[c], positional: ("body",)))
#assert(rebuilds(grid.cell[c], positional: ("body",)))

// A single positional field under a name other than `body`.
#assert(rebuilds([hello], positional: ("text",)))
#assert(rebuilds(raw("code"), positional: ("text",)))
#assert(rebuilds(metadata((a: 1)), positional: ("value",)))
#assert(rebuilds(h(1em), positional: ("amount",)))
#assert(rebuilds(v(1em), positional: ("amount",)))
#assert(rebuilds(ref(<lbl>), positional: ("target",)))
#assert(rebuilds(cite(<key>), positional: ("key",)))

// Two positional fields, in declaration order.
#assert(rebuilds(align(center)[x], positional: ("alignment", "body")))
#assert(rebuilds(place(top)[x], positional: ("alignment", "body")))
#assert(rebuilds(columns(2)[x], positional: ("count", "body")))
#assert(rebuilds(terms.item([a], [b]), positional: ("term", "description")))
#assert(rebuilds(text(size: 12pt)[hello], positional: ("child", "styles")))
#assert(rebuilds(
  link("https://example.com")[x],
  positional: ("dest", "body"),
))

// A sequence takes its children array as one positional argument.
#assert(rebuilds([*a* b], positional: ("children",)))

// Variadic containers spread their children array into positional arguments.
#assert(rebuilds(list([a], [b]), positional: ("children",), spread: true))
#assert(rebuilds(enum([a], [b]), positional: ("children",), spread: true))
#assert(rebuilds(grid([a], [b]), positional: ("children",), spread: true))
#assert(rebuilds(stack([a], [b]), positional: ("children",), spread: true))
#assert(rebuilds(table([a], [b]), positional: ("children",), spread: true))
#assert(rebuilds(
  terms(terms.item([a], [b])),
  positional: ("children",),
  spread: true,
))
#assert(rebuilds(
  polygon((0pt, 0pt), (1cm, 0pt), (0pt, 1cm)),
  positional: ("vertices",),
  spread: true,
))
#assert(rebuilds(
  curve(curve.line((1cm, 1cm))),
  positional: ("components",),
  spread: true,
))
#assert(rebuilds(
  $mat(1, 2; 3, 4)$.body,
  positional: ("rows",),
  spread: true,
))

// ---------------------------------------------------------------------------
// Elements that cannot be reconstructed at all.
//
// `image` compares by instance identity rather than by field value, so no
// rebuild can ever equal the original. The registry must treat it as an opaque
// leaf and never rebuild or compare it.
//
// Typst memoises a call, so two calls at the same call site with the same
// arguments return the same instance and do compare equal. Any test of image
// equality has to use two distinct call sites or it silently proves nothing.
// ---------------------------------------------------------------------------

#let svg-bytes = bytes(
  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1\" height=\"1\"></svg>",
)

#let img-a = image(svg-bytes, format: "svg")
#let img-b = image(svg-bytes, format: "svg")

// Same arguments, distinct call sites, unequal.
#assert(not (img-a == img-b))

// Same call site, so memoisation hands back the same instance.
#let same-site() = image(svg-bytes, format: "svg")
#assert.eq(same-site(), same-site())

// A rebuild is always a fresh call site, so it can never round trip.
#assert(not rebuilds(img-a, positional: ("source",)))

// The rebuilt image is field-identical to the original and still unequal,
// which is what distinguishes this from a rebuild that loses information.
#let img-rebuilt = rebuild(img-a, positional: ("source",))
#assert.eq(img-rebuilt.fields(), img-a.fields())

// ---------------------------------------------------------------------------
// Labels are invisible to equality.
//
// A label appears in fields() but is not a constructor parameter, so every
// rebuild silently drops it, and equality does not notice. Rebuilding must
// therefore reattach the label explicitly rather than rely on a round trip
// check. These assertions pin that behaviour down so a future Typst release
// that fixes it is noticed.
// ---------------------------------------------------------------------------

#let labelled = [#block[x] <lbl>].children.first()

#assert.eq(labelled.label, <lbl>)
#assert("label" in labelled.fields())
#assert(not ("label" in block[x].fields()))

// Equality ignores the label entirely.
#assert.eq(block[x], labelled)

// The naive rebuild drops it, and still compares equal.
#let stripped = (labelled.func())(labelled.body)
#assert(not ("label" in stripped.fields()))
#assert.eq(stripped, labelled)

// Reattaching the label in markup restores it without wrapping in a sequence.
#let relabelled = [#stripped#labelled.label]
#assert.eq(relabelled.func(), block)
#assert.eq(relabelled.label, <lbl>)

roundtrip tests passed.
