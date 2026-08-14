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
  Inside a show rule, `figure` gains a `counter` field and `raw` gains a `lines` field.
  Neither is a constructor parameter, so both must be dropped when the element is reached from a show rule.
  Dropping more is wrong: removing `scope` from `figure` or `theme` from `raw` produces a rebuild that no longer compares equal.
- **`image`.**
  Image equality is instance identity rather than field equality, so no rebuild can ever equal the original.
  It is deliberately absent from the registry and must be treated as an opaque leaf that the traversal never descends into and never reconstructs.
