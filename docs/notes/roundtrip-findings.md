# Element round trip findings

## Verdict

**Generic reconstruction does not hold.**
`(node.func())(..node.fields())` reconstructs 6 of the 59 elements probed, which is roughly one in ten.
The other 53 do not merely return an unequal value, they panic at compile time.

This is not a marginal shortfall that a handful of registry entries can absorb.
Any design that treats generic reconstruction as the default and the registry as the exception list has the two the wrong way round.

The mechanism is nonetheless salvageable, and cheaply.
A single corrected rule reconstructs 58 of the 59 elements, and that rule was verified against every element in the candidate set.
It is stated in [The rule that does hold](#the-rule-that-does-hold), and the recipe for each element is tabulated in [Registry recommendations](#registry-recommendations-for-task-5).

## Method

Probed against `typst 0.15.1`.

Each element was probed in its own `typst eval` process.
Typst cannot catch a panic, so a single shared document would have stopped at the first failing element and hidden every later one.
Each probe recorded three things separately: whether `fields()` could be read, whether the rebuild panicked and with what message, and whether the rebuilt value compared equal to the original.

Every error quoted below is the verbatim first line of the Typst diagnostic.

## The rule that does hold

`fields()` returns a dictionary, and spreading a dictionary supplies named arguments only.
Typst element constructors take many of their parameters positionally, and a positional parameter cannot be supplied by name.
That single mismatch accounts for all 53 failures.

The corrected rule is to split the field dictionary before spreading it.

```typst
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
```

Fields named in `positional` are passed positionally, in declaration order, after the remaining fields are passed by name.
`spread: true` covers variadic containers, whose single positional field holds an array that must itself be spread into separate arguments.

This rule reconstructs 58 of the 59 elements.
The one exception is `image`, which cannot be reconstructed by any means, for reasons given in [Elements that cannot be reconstructed at all](#elements-that-cannot-be-reconstructed-at-all).

## List 1: elements that round trip cleanly

These reconstruct correctly under the unmodified generic mechanism.

- `space`, obtained as `[ ]`, which has no fields.
- `linebreak`, which has no fields.
- `parbreak`, which has no fields.
- `pagebreak`, which has no fields.
- `outline`, as `outline()`, which has no fields.
- `line`, as `line(length: 1cm)`, whose fields are all named parameters.

The common property is that the field set contains no positional parameter.
It is not a property of the element type.
The same element succeeds or fails depending on which fields happen to be set, so `block(width: 1cm)` round trips while `block[hello]` panics.
Both behaviours are asserted in `tests/unit/test-roundtrip.typ`.

There is a second, narrower failure mode in the same area.
An element whose positional parameter is *required* fails even when that field is unset, because the constructor then has nothing to bind.
`par(leading: 1em)` and `text(size: 12pt)` both fail this way with `missing argument: body`.

## List 2: elements that fail

All 53 failures panic.
None of them returns an unequal value, so none can be asserted negatively in a committed test.
They fall into three error classes.

### Class A: the field maps to an optional positional parameter

Verbatim error, with the field name varying:

```text
error: the argument `body` is positional
```

| Element | Fields probed | Verbatim error |
| --- | --- | --- |
| `heading` | `level`, `body` | ``the argument `body` is positional`` |
| `emph` | `body` | ``the argument `body` is positional`` |
| `strong` | `body` | ``the argument `body` is positional`` |
| `figure` | `body`, `caption` | ``the argument `body` is positional`` |
| `list.item` | `body` | ``the argument `body` is positional`` |
| `enum.item` | `body` | ``the argument `body` is positional`` |
| `align` | `alignment`, `body` | ``the argument `body` is positional`` |
| `place` | `alignment`, `body` | ``the argument `body` is positional`` |
| `footnote` | `body` | ``the argument `body` is positional`` |
| `par` | `body` | ``the argument `body` is positional`` |
| `columns` | `count`, `body` | ``the argument `body` is positional`` |
| `quote` | `body` | ``the argument `body` is positional`` |
| `math.equation` | `block`, `body` | ``the argument `body` is positional`` |
| `pad` | `left`, `top`, `right`, `bottom`, `body` | ``the argument `body` is positional`` |
| `hide` | `body` | ``the argument `body` is positional`` |
| `underline` | `body` | ``the argument `body` is positional`` |
| `overline` | `body` | ``the argument `body` is positional`` |
| `strike` | `body` | ``the argument `body` is positional`` |
| `highlight` | `body` | ``the argument `body` is positional`` |
| `smallcaps` | `body` | ``the argument `body` is positional`` |
| `sub` | `body` | ``the argument `body` is positional`` |
| `super` | `body` | ``the argument `body` is positional`` |
| `repeat` | `body` | ``the argument `body` is positional`` |
| `figure.caption` | `body` | ``the argument `body` is positional`` |
| `table.cell` | `body` | ``the argument `body` is positional`` |
| `grid.cell` | `body` | ``the argument `body` is positional`` |
| `raw` | `text` | ``the argument `text` is positional`` |
| `styled` | `child`, `styles` | ``the argument `child` is positional`` |
| `terms.item` | `term`, `description` | ``the argument `term` is positional`` |
| `metadata` | `value` | ``the argument `value` is positional`` |
| `sequence` | `children` | ``the argument `children` is positional`` |
| `h` | `amount` | ``the argument `amount` is positional`` |
| `v` | `amount` | ``the argument `amount` is positional`` |
| `ref` | `target` | ``the argument `target` is positional`` |
| `cite` | `key` | ``the argument `key` is positional`` |
| `image` | `source`, `format` | ``the argument `source` is positional`` |

For `align` and `place` both `alignment` and `body` are positional, and Typst reports only the first offending argument.

### Class B: the field has no named form at all

Verbatim error, with the field name varying:

```text
error: unexpected argument: body
```

These are positional-only or variadic parameters.
Typst does not recognise the name at all, so the diagnostic is `unexpected argument` rather than `is positional`.

| Element | Fields probed | Verbatim error |
| --- | --- | --- |
| `block` | `body` | `unexpected argument: body` |
| `box` | `body` | `unexpected argument: body` |
| `rect` | `body` | `unexpected argument: body` |
| `circle` | `body` | `unexpected argument: body` |
| `ellipse` | `body` | `unexpected argument: body` |
| `square` | `body` | `unexpected argument: body` |
| `list` | `children` | `unexpected argument: children` |
| `enum` | `children` | `unexpected argument: children` |
| `grid` | `children` | `unexpected argument: children` |
| `stack` | `children` | `unexpected argument: children` |
| `table` | `children` | `unexpected argument: children` |
| `terms` | `children` | `unexpected argument: children` |
| `polygon` | `vertices` | `unexpected argument: vertices` |
| `curve` | `components` | `unexpected argument: components` |
| `math.mat` | `rows` | `unexpected argument: rows` |

Note that `block` and `box` land here while `heading` and `figure` land in class A.
The distinction is invisible from the field name, so a registry cannot infer it and must record it.

### Class C: the field name differs from the parameter name

| Element | Fields probed | Verbatim error |
| --- | --- | --- |
| `link` | `dest`, `body` | `missing argument: destination` |
| `text` | `text` | `missing argument: body` |

`link` exposes its destination under the field name `dest` but accepts it under the parameter name `destination`.
The text element exposes its content under the field name `text` but accepts it under the parameter name `body`.
In both cases the value is passed positionally, so the name mismatch never has to be resolved, but any registry that tries to remap fields by name will trip over it.

## List 3: elements whose fields cannot be read at all

None.

`fields()` was readable on all 59 elements probed, including `styled`, `sequence`, `space` and `image`.
No element in the candidate set needs an extract entry purely because its fields are inaccessible.

## Elements that cannot be reconstructed at all

`image` is the only one.

The corrected rule builds an image whose fields are identical to the original, and the two still compare unequal.
Image equality is instance identity, not field equality.

There is a trap in testing this.
Typst memoises a call, so two calls at the *same* call site with the same arguments return the same instance and do compare equal.
Two calls at *distinct* call sites with the same arguments do not.
An equality test written with a helper function therefore proves nothing, because both calls share the helper's call site.
This was hit during the spike and is pinned down by assertions in the test file.

A rebuild is always a fresh call site, so `rebuild(img) == img` is false unconditionally and cannot be fixed.

## Further findings that affect the registry

### Labels are invisible to equality

This is the most dangerous finding in this note, because it makes the round trip check itself unreliable.

A labelled element exposes `label` in `fields()`, but `label` is not a constructor parameter.
Passing it by name gives `unexpected argument: label`.
Every rebuild therefore drops the label, and equality does not notice, because content equality ignores labels entirely.

Concretely, `block[x] == [#block[x] <lbl>].children.first()` is `true`.

A rebuild that silently loses every label will pass a round trip test cleanly.
The registry must strip `label` from the field dictionary before spreading and reattach it afterwards.
Reattachment works by markup concatenation, and preserves the element rather than wrapping it in a sequence.

```typst
#let relabelled = [#rebuilt#original.label]
```

### Synthesised fields break the rebuild inside show rules

`fields()` returns more fields inside a show rule than on freshly constructed content, because the element has been synthesised.
Several of those synthesised fields are not constructor parameters.

- `figure` gains `counter`, and rebuilding inside `show figure:` fails with `unexpected argument: counter`.
- `raw` gains `lines`, and rebuilding inside `show raw:` fails with `unexpected argument: lines`.
- `figure.caption` gains `kind`, `supplement`, `numbering` and `counter`, and rebuilding inside either `show figure:` or `show figure.caption:` fails with `unexpected argument: kind`.
- `ref` gains `citation` and `element`, and rebuilding inside `show ref:` fails with `unexpected argument: citation`.

Dropping exactly those keys restores an equal rebuild in every case.
Dropping more is wrong: removing `scope` from `figure` or `theme` from `raw` produces a rebuild that no longer compares equal.

Every other element tested inside a show rule rebuilds correctly under the standard rule, including `heading`, `list`, `enum`, `grid`, `stack`, `table`, `terms`, `quote`, `footnote`, `math.equation`, `strong`, `emph`, `par` and `block`.

If the traversal only ever sees content as authored, this does not arise.
If it can be reached from a show rule, every key listed above needs dropping.

### Two shapes are not what they look like

- `[a b]` is a single text element, not a sequence, because adjacent text is merged.
  A genuine sequence needs mixed content, such as `[*a* b]`.
- `text(size: 12pt)[hello]` produces a `styled` element wrapping a text element, not a text element.
  Setting a text property never yields a text node, so a registry keyed on `text` will not intercept it.
  `styled` has positional fields `child` and `styles`, and rebuilds correctly under the standard rule.

### A sequence does not spread

`sequence` takes its children array as a *single* positional argument.
The variadic containers, `list`, `enum`, `grid`, `stack`, `table`, `terms`, `polygon`, `curve` and `math.mat`, spread theirs into separate arguments.
Getting this backwards fails loudly in both directions.
Spreading a sequence's children gives `expected array, found content`, and passing a container's children as one argument gives `expected content, found array`.

### Passing a raw array to terms is deprecated

Constructing `terms(([a], [b]))` emits:

```text
warning: implicit conversion from array to `terms.item` is deprecated
```

The children returned by `fields()` are already `terms.item` elements, so a rebuild never triggers this.
It only affects test fixtures written by hand.

## Registry recommendations for Task 5

Every entry below was verified to produce a value equal to the original.
`spread` means the single positional field holds an array that must be spread into separate positional arguments.

Recommended default: treat the corrected rule as the default and record only the positional field list per element.
A listed field that the instance does not carry is skipped rather than indexed, because an unset optional positional parameter is absent from `fields()` altogether.
That is what makes a single entry cover both `enum.item(3)[a]` and `enum.item[a]`, and both `place(top)[x]` and `place(dx: 1pt)[x]`.

An element absent from the registry cannot be assumed to have no positional fields.
That assumption holds for the six in list 1, but not in general: `rotate`, `scale`, `move` and `skew` fail with `the argument 'body' is positional`; `math.frac`, `math.attach`, `math.lr`, `math.vec`, `math.cases`, `math.accent` and `math.root` fail similarly; `table.header`, `table.footer`, `grid.header` and `grid.footer` fail with `unexpected argument: children`.
Any traversal that descends into an equation reaches one of these immediately, so "absent from the registry" has to mean "unknown", not "safe to spread".

| Element | Positional fields, in order | Spread |
| --- | --- | --- |
| `block`, `box`, `rect`, `circle`, `ellipse`, `square` | `body` | no |
| `heading`, `emph`, `strong`, `figure` | `body` | no |
| `list.item` | `body` | no |
| `enum.item` | `number`, `body` | no |
| `footnote`, `par`, `quote`, `pad`, `hide` | `body` | no |
| `underline`, `overline`, `strike`, `highlight`, `smallcaps` | `body` | no |
| `sub`, `super`, `repeat` | `body` | no |
| `figure.caption`, `table.cell`, `grid.cell` | `body` | no |
| `math.equation` | `body` | no |
| `text`, `raw` | `text` | no |
| `metadata` | `value` | no |
| `h`, `v` | `amount` | no |
| `ref` | `target` | no |
| `cite` | `key` | no |
| `sequence` | `children` | no |
| `align`, `place` | `alignment`, `body` | no |
| `columns` | `count`, `body` | no |
| `terms.item` | `term`, `description` | no |
| `styled` | `child`, `styles` | no |
| `link` | `dest`, `body` | no |
| `list`, `enum`, `grid`, `stack`, `table`, `terms` | `children` | yes |
| `polygon` | `vertices` | yes |
| `curve` | `components` | yes |
| `math.mat` | `rows` | yes |

### Entries added after the spike

The spike probed elements a deck author writes by hand.
Generated output reaches wider, so entries added later are recorded here with the evidence that forced them.

| Element | Positional fields, in order | Spread | Why it was added |
| --- | --- | --- | --- |
| `table.header` | `children` | yes | Emitted by Quarto for every Markdown table that has a header row, as seen in `tests/fixtures/quarto-deck.typ`. |

Before this entry, a marker in a header cell panicked with `cannot reconstruct element header containing a step marker`, which is the correct behaviour for an unregistered element and the wrong outcome for a table a user simply wrote in Markdown.

`table.footer`, `grid.header` and `grid.footer` share the recipe and are deliberately absent.
Nothing observed emits them, and the registry records verified need rather than symmetry.
`table.footer` is the unregistered element that `tests/unit/test-walk-rebuild.typ` uses to demonstrate the hard failure and its remedy.

`table.hline` and `table.vline` need no entry.
Neither takes content, so neither can carry a marker.

### Entries that need more than a positional list

- `image`: mark as an opaque leaf.
  Do not rebuild it and do not compare it.
  Extract should return no children, so the traversal never descends into it and never needs to reconstruct it.
- Any labelled element: strip `label` from the fields before spreading, and reattach it with `[#rebuilt#label]` afterwards.
  This is cross-cutting rather than per element, so it belongs in the shared rebuild helper, not in individual registry entries.
- `figure` reached from a show rule: also drop `counter`.
- `raw` reached from a show rule: also drop `lines`.

## Regression guard

`tests/unit/test-roundtrip.typ` asserts all of the above that can be asserted.

It cannot assert the 53 panicking cases negatively, because a panic aborts compilation and Typst offers no way to catch it.
It asserts the corrected recipe for each of them instead, which is the stronger guard: it pins the exact contract the registry implements, so an upstream change breaks the build and forces the registry to be revisited.

The only genuinely negative assertion available is `image`, which fails by inequality rather than by panic.
