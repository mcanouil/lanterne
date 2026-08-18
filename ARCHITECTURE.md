# Architecture

Design decisions that are not obvious from the code, and the reasoning behind them.

## The container registry is a value, not document state

`src/core/registry.typ` records which fields of each element must be handed back positionally when the element is rebuilt.
The entry set comes from `notes/roundtrip-findings.md`, which characterised 59 elements against Typst 0.15.1.

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
Three concerns from `notes/roundtrip-findings.md` are cross-cutting rather than per element, so they belong in the shared rebuild helper and not in registry entries.

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
A fallback would therefore turn an unknown element into one of the cryptic diagnostics catalogued in `notes/roundtrip-findings.md`, reported against a line inside the traversal and with no remedy attached.

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

## The expansion is a separate module from the step surface

`src/core/steps.typ` is the step surface: the calls an author writes, `step`, `uncover`, `only`, `dim`, `focus`, `pause` and `context-slide`.
`src/core/expand.typ` is the resolution: turning a stepped body into one body per step, reading the markers `steps.typ` built.
`steps.typ` carries the name specification 3.1 gave the step surface module, so the file an author reads to learn the calls is the file the specification already points at.

### Decision

The two stay separate modules rather than one.

`steps.typ` validates at the call the author wrote: a range is parsed, a state is checked against the enumeration, and a heading inside the region is refused there, all before the marker exists.
That is what lets an error name the call and the line, per specification's own grammar for every guard in the package.

`expand.typ` cannot do any of that at the point a marker is built, because it does not run until the whole slide body is known.
Counting a slide's steps needs every marker collected first: the total is the highest step any span mentions, or one more than the number of pauses, whichever is larger, and neither number exists until the traversal has walked the body once.
A module that validated per call and also counted across calls would run two passes for two different reasons at two different times, inside one function.

Splitting on that boundary, call time against resolution time, is the same reason `slides.typ` and `record.typ` stay apart: `slide-record` validates what one slide was given, and `slides` decides which segment of the document became that slide.

## The step surface and the machine surface converge on one primitive

`step` in `src/core/steps.typ` is the one primitive; `uncover`, `only`, `dim` and `focus` are it with `before` and `after` set.
`emit-step` in `src/emit/step.typ` is the same primitive behind a surface built for a filter: plain dictionaries, strings and content, no closures, no positional variadics.

### Decision

`emit-step` delegates to `step` and passes its own scope, so a range malformed by a filter reports under `emit-step` and one written by hand reports under `step`.
Neither module imports the other's callers; both import the one primitive that validates.

### Why not the other direction

The ergonomic alternative looked like having `steps.typ`'s aliases call through `emit-step`, so the range and state parsing lived in one place nearer the filter-facing surface.
That inverts the layer order the rest of the package holds to.
`src/emit/` exists to translate a machine shape into what `src/core/` already validates, which is why it imports from `core` and `core` imports nothing from `emit`.
Reversing that particular import would leave every other module in `core`, `record.typ`, `slides.typ`, `range.typ`, still depending on nothing above it, except this one function depending on the layer built to depend on it.
A reader tracing why an ordinary `#pause` call touches the emitter would find no reason, because there is none: the convergence a filter needs is at `step`, not at `emit-step`.

## The dimmed state sets the text fill

`_resolve` in `src/core/expand.typ` renders a `dimmed` region by calling `dim`, a function threaded in as an argument rather than read from a default.
`deck` in `src/render/deck.typ` builds that function from the theme: `text(fill: tokens.fg.transparentize(100% - tokens.dim-opacity), region)`.

### Decision

Dimming sets the text fill because Typst 0.15 has no content opacity, and `src/core/` reads no theme, so the renderer is the only layer that has both the tokens and the moment the body is threaded through `rebuild`.

### What this does not cover

`text` governs glyph colour only.
An image inside a dimmed region does not dim, because an image carries no fill.
An explicit fill on a shape, a block or a colour set some other way inside the region does not dim either, because it was never routed through `tokens.fg`.
A stroke is the same: nothing here touches `stroke`.
This is documented at the export, in `docs/reference.qmd` and in `steps.typ`'s own doc comment for `dim` and `focus`, rather than discovered on stage.

### Why an overlay rectangle was rejected

An overlay that visually dims a region has to be sized and positioned to match it, which needs to know what the region measures once laid out.
Typst answers that only inside `context`, through `measure` or `layout`, and a marker inside a `context` block is already established as invisible to the traversal: a context block reports no fields until layout resolves it, which is why `#pause` and every step function have to be written outside one.
An overlay approach would reintroduce exactly that problem to solve a problem the traversal already has an answer for, and would do it inside `_resolve`, which has to return content synchronously from a plain recursive walk with no layout pass available to it.

Setting the text fill needs neither a size nor a position.
It composes with `rebuild`'s synchronous transform the same way the `visible`, `hidden` and `removed` states already do, and it is one call rather than a second content layer to keep in front of or behind the first.

## Counters are shifted by arithmetic, never captured

A slide renders one page per step and emits its body again on each, so everything the document numbers is numbered again.
The counters are put back by subtracting what the body advances, counted from the body itself, and a region that resolves to `removed` advances them in its place.

### Decision

`src/core/counters.typ` counts the increments a body makes and returns content that shifts each counter by that count.
`deck` writes the rewind at the head of every step but the first, and only for a slide that renders more than one step.
Nothing reads a counter.

The count is taken from the body as written, markers and all, so it is the same number whatever step is being built.
That is what makes every step advance the counters equally, which is the property the numbering rests on.

Only the eligibility test reads anything, and it reads a style: a figure advances unless its numbering is `none`, an equation only when block level and numbered.
Reading a style inside `context` is safe, where reading a counter is not.

### Why capture and restore was rejected

Reading the counter with `get` at the start of a slide, keeping it in a `state` and putting it back on the next step is the obvious approach, and it does not converge.
The captured value is introspective, and it reaches the next slide through document state, so the information advances about one slide per layout run where Typst allows five.

Three stepped slides already emit `value of state did not converge` and render the same figure with two different numbers; thirty emit 118 warnings.
The document still exits zero, which is why `tools/check.sh` now fails a compile that warns.
The measurement is in `notes/counter-findings.md`, and the rejected mechanism is kept in the build as `tests/expect-warn/state-does-not-converge.typ`.

### What this does not cover

A counter of the author's own cannot be frozen: its updates are opaque content, so the count a relative shift needs cannot be taken from the body.
The same applies to anything numbered inside a `context` block, inside a `show` rule body, or by a `context-slide` callback, none of which the walk can see.

`counter(heading)` is hierarchical, so subtraction has no inverse for it.
A heading is kept from advancing instead, by a `set heading(numbering: none)` rule on the step pages that repeat it.
