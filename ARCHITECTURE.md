# Architecture

Design decisions that are not obvious from the code, and the reasoning behind them.

## The container registry is a value, not document state

`src/core/registry.typ` records which fields of each element must be handed back positionally when the element is rebuilt.
The entry set comes from `docs/notes/roundtrip-findings.md`, which characterised 59 elements against Typst 0.15.1.

### Decision

`register-container` is a pure function returning a new registry dictionary, and the registry is threaded through the deck configuration.
`builtin-registry()` is the base.
`lookup(fn, registry: none)` reads the built in set unless a threaded registry is supplied.

The alternative, holding user registrations in a `state`, was rejected.

### Why not `state`

Three reasons, any one of which is sufficient.

- `state` is context dependent.
  Reading it needs `state.get()` inside `context`, so `lookup` would only be callable from a context block.
  The traversal that consumes the registry is a plain recursive walk over content that has to return content synchronously, including from inside a show rule.
  Forcing every lookup into `context` would push the whole traversal into a deferred computation for no gain.
- `state` is document-order dependent.
  `state.get()` sees only the updates that appear before that point in the document, so the same element could resolve differently depending on where it sits in the deck.
  Which fields an element takes positionally is a static property of Typst, so a position-dependent answer is always a bug.
- `state.update` returns content that has to be placed in the document to take effect.
  A registration function whose return value must be joined into the output, and which silently does nothing otherwise, is a poor interface.

Threading a value has none of these problems, and it makes the registry testable without a layout pass.
`tests/unit/test-registry.typ` proves the point directly: registrations are visible immediately after being made, the built in registry is left untouched, and a threaded registry gives the same answer inside a `context` block as outside one.

### Why the entries are bucketed by `repr`

Typst dictionary keys must be strings, so an element function cannot be a key directly.
`repr` is the obvious string form and it is **not** injective over element functions: `repr(list.item)`, `repr(enum.item)` and `repr(terms.item)` are all `"item"`, `repr(table.cell)` and `repr(grid.cell)` are both `"cell"`, and `repr(table.header)` and `repr(grid.header)` are both `"header"`.
A registry keyed on `repr` alone silently answers one element for another.
The `"item"` bucket is the one that would actually corrupt a lookup, because `terms.item` carries a different recipe from the other two rather than the same one.

Entries are therefore bucketed by `repr(fn)` and disambiguated within the bucket by comparing the function value itself, which does distinguish them.
Lookup stays a dictionary access plus a scan of at most three entries.

## What the registry deliberately does not do

The registry supplies data and a lookup.
It does not rebuild anything.
Three concerns from `docs/notes/roundtrip-findings.md` are cross-cutting rather than per element, so they belong in the shared rebuild helper and not in registry entries.

- **Labels.**
  A labelled element exposes `label` in `fields()`, but `label` is not a constructor parameter, so passing it back gives `unexpected argument: label`.
  Every rebuild drops the label, and content equality does not notice, because equality ignores labels entirely.
  The helper must strip `label` before spreading and reattach it afterwards with `[#rebuilt#label]`.
- **Synthesised fields.**
  Inside a show rule, `figure` gains a `counter` field, `raw` gains a `lines` field, `figure.caption` gains `kind`, `supplement`, `numbering` and `counter`, and `ref` gains `citation` and `element`.
  None of them is a constructor parameter, so all must be dropped when the element is reached from a show rule.
  Dropping more is wrong: removing `scope` from `figure` or `theme` from `raw` produces a rebuild that no longer compares equal.
- **`image`.**
  Image equality is instance identity rather than field equality, so no rebuild can ever equal the original.
  It is deliberately absent from the registry and must be treated as an opaque leaf that the traversal never descends into and never reconstructs.

## Reconstruction refuses an unregistered element

`rebuild` in `src/core/walk.typ` panics when an element carrying a marker has no registry entry, rather than falling back to spreading its fields by name.

An element absent from the registry has no positional fields, which is the right reading when nothing has to be rebuilt.
It is not a safe assumption when something does.
The absence cannot be told apart from an element nobody has characterised yet, `outline.entry` being an obvious remaining example in the standard library, and Typst offers no way to inspect the parameters of a function or to catch the panic that a wrong guess raises.
A fallback would therefore turn an unknown element into one of the cryptic diagnostics catalogued in `docs/notes/roundtrip-findings.md`, reported against a line inside the traversal and with no remedy attached.

Refusing costs a registration for an element whose marker sits in a field that is passed by name, an `outline` title being the only realistic instance.
It buys a message that names the element and the call that fixes it, on every element the package has not characterised.
Because `repr` is not injective over element functions, the message carries the element's field names alongside its name, so `table.header` and `grid.header` can be told apart in the diagnostic as well as in the registry.
A deck that silently lost a step boundary is worse than a deck that failed to build.

This is not a total guarantee.
A marker inside a `context` block is invisible to detection, because a context block reports no fields until layout resolves it, so nothing reaches reconstruction to refuse.
`#pause` has to be written outside `context`.

## A slide is its own `page(...)` call

`deck` in `src/render/deck.typ` emits one `page(...)` call per slide record, rather than setting the page once and separating slides with weak page breaks.

Both render the same deck today.
The call form is chosen because one page per slide is then structural rather than incidental: a slide that emitted two pages would need a second call, so a spurious page is a bug in the emitter rather than an overflow nobody notices.
It is also what the later milestones need.
A slide that bleeds sets the page `bleed` parameter, and a slide with a fill of its own sets `fill`, and neither can be said once for the whole deck.

The cost is that every page carries the full page configuration rather than inheriting it, which is a dictionary of four values per slide.

## The slide's title stays where it was written

The heading that opens a slide is left at the head of that slide's body rather than being lifted out and re-emitted by the renderer.
`split-at` reports it so the record can describe the slide, and `keep` leaves it in place so the body still contains it.

Lifting it out looked tidier and was wrong.
A `set` or `show` rule wraps everything it governs, and the splitter puts that wrapper back around each segment, so a heading re-emitted beside the wrapper is outside every rule the document set.
Three things break at once, all of them silently: `set heading(numbering: ...)` no longer numbers the title, a `show heading` rule no longer restyles it, and a reference to a labelled slide fails with `cannot reference heading without numbering` because the numbered heading Typst was asked to resolve was never the one that rendered.
No equality assertion catches any of this, because the deck still builds and the title still appears.

The cost is that `record.title` describes the slide rather than being the only copy of it.
A renderer that later wants the title in a header region has to take it out of the body deliberately, inside the wrappers, rather than finding it already separated.

## The slide record carries no `layout` key

The record in `src/core/record.typ` describes a slide with `kind`, `title`, `level`, `label`, `attrs` and `body`.
The specification's machine surface also shows a `layout` key, and it is deliberately absent until the layout system lands.

The rule is the one `src/theme/tokens.typ` states for tokens: a vocabulary carries only the names something reads, and grows as the code that reads them lands.
A `layout` key today would be validated against a catalogue that does not exist, stored, and consulted by nothing, so no reader could check what a value in it means and no test could fail when it was wrong.
The same rule governs the option vocabulary, which ships `smaller` alone, and the `info` keys, which ship the three `set document` reads.

Growing a vocabulary is additive and breaks no deck.
Shipping a name that means nothing yet cannot be taken back.
