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
`split-head` is the tool for that, and the ruling below says why it is a third splitter rather than a call to one of the first two.

## `split-head` mirrors the splitter rather than calling it

`split-head` in `src/core/split.typ` takes the first child a predicate matches out of a body and hands back both halves inside the wrappers they were found under.
It repeats the shape of `_pieces` rather than reusing it, which is a duplication the three-duplications rule would otherwise refuse.

The reason is the label rule below, not the wrapper rebuild.
`_relabel` places one label among n pieces that render in sequence; this places one among exactly two that render on the same page, and the two rules disagree.
Reuse would mean threading a second placement rule through a function whose whole job is the first one.

The wrapper argument is worth stating precisely, because it cuts both ways.
`_pieces` cuts at every match, so rebuilding a body from pieces 1 to n means summing separately wrapped pieces, and applying `#set page` twice within one segment opens two page groups: a body that rendered on one page comes back rendering on two.
`split-head` produces two separately wrapped halves and so can do the same thing.
**A caller must place the halves in different regions and must never rejoin them.**
`cut.head + cut.rest` is not the body that went in, and the failure is a spurious page rather than an error.
A caller with no region to put the head in must not call this at all; it must leave the body whole, which is what a theme supplying no header slot does.

### Where a divided group's label goes

A label on a wrapper or a sequence marks the slide's content, so it stays with the rest rather than travelling with the title being moved away from it.
It falls to the head only when the rest carries nothing, which is the title-only slide specification 4.1 allows.
A label on the heading itself is one of its fields and travels with it either way, which is what makes a reference to a labelled slide resolve.

**This departs from the first-appearance rule of specification 4.6**, which `_relabel` follows and which sends a divided group's label to the first piece that carries something.
The departure is deliberate and is confined to this function.
4.6 governs pieces that render on different pages, where first appearance decides which page a reference lands on.
Both halves of a `split-head` cut render on the same page, one in a region and one in the body, so a reference resolves to the same page either way and the rule is free to say something else.
It says the label marks content, because that is what an author labelling a group meant.

Within the rest the label goes on the first node that carries something.
That much *is* `_relabel`'s rule, for `_relabel`'s reason: markup attaches a label to the last element of what it follows, and the last element of a divided group is usually the space beside a boundary, which a later stage merges away.
Where this call divided nothing, a label on a blank half is degraded rather than refused, matching `_relabel`'s own undivided-group branch.

### What the caller has to supply

The function is deliberately weaker than the splitter that produces a slide, so the contract is stated here rather than discovered.

- The predicate identifies the slide's own title, not the first heading in the body.
  `slides` guarantees the title is the *first child*; `split-head` matches the first child that *satisfies the predicate*, which is a weaker property, so a body carrying an `#include`d sequence can present a heading the caller did not mean.
  The caller narrows this by matching a heading at the record's own level, and by calling only when the record has a title at all.
- `record.title` describes the slide and `cut.head` renders it.
  Both exist once a caller lands, and they are not interchangeable: `record.title` is the heading's `body` field with no wrappers, so no rule reaches it.
- The counters are unaffected.
  `increments` counts the record's body as written, before any split, so taking the title out of a step body afterwards changes no number.
- `rest` is blank rather than `[]` when a slide is nothing but its title, since the wrappers come back around nothing.
  Emptiness is read with `is-blank`, as `slides` already reads it for a lead-in segment.

`_title` in `src/render/deck.typ` is the caller. It places the head in a region and the rest in the body and never rejoins them, which are the two obligations that bite.
It never tests the rest for emptiness, so the third is met vacuously: a blank rest composes a body region carrying nothing, which is what a title-only slide should look like.
The function landed a branch ahead of that caller because a pure function with its own tests is reviewable on its own, and the branch that wired it had enough in it already.

## A slot's output stays inside the page's own rules

`_slide-page` in `src/render/deck.typ` composes a page from regions, and every one of them is emitted in the flow of the page body.
Nothing goes to `page(header: ...)`.

Content handed to `page(header:)` is styled at the `page` call site, and every rule this renderer sets is written inside the page body: `set text`, `set par`, the `show heading` that sizes a title, and the computed `set heading(...)` that suppresses a repeat.
A title placed in Typst's own header would lose its font, its size, its show rule and its suppression rule at once, and would sit outside the flow the outline, the bookmarks and a reference read.

`_chrome` wraps the whole composed page rather than the body region.
That is the half of the rule which is easy to get wrong: a title moved into a header region beside the suppression would escape it, so the heading counter would advance once per step, the outline would list the slide once per step, and the PDF would gain a bookmark per step.
Those are exactly the three failures the correctness milestone removed.

A title slide is emitted through the same page function as every slide, with a synthetic record and a flag.
The flag is what is load-bearing: no record kind can express what a title slide needs, since a record of kind `content` yields `bookmarked: false` alone, and a heading a theme writes into its title slide would then be outlined and would advance the hierarchical heading counter with nothing able to put it back.
The same flag keeps the deck's own regions off that page, because a title slide is not a slide of the deck and its chrome does not belong there.

## The title moves only when something will place it

`split-head` runs on a step's body when the theme supplies a slot that places a title on that page: `render-header` on a content slide, `render-section-slide` on a section slide.
It does not run otherwise, and a theme supplying no slot at all renders the page it always rendered, which the visual goldens assert.

Taking the title out with nowhere to put it would delete it from the slide.
That is why the condition is the slot rather than the presence of a title, and why a theme with only a footer leaves the body whole.

The split runs after step expansion, per page, rather than once per slide.
`expand` splits on pauses first and refuses a heading after a pause, so the opening heading is always in the first segment and survives the rebuild as a top level child.
`increments` counts the record's body as written, before any of this, so taking a title out of a step body afterwards moves no number.

The predicate matches a heading at the record's own level.
`split-head` takes the first child that *satisfies the predicate*, which is weaker than the first child that `slides` guarantees, so a level-blind predicate would lift a heading out of an included sequence, out of a `context-slide` callback's result, or out of a slide that a `slide-level` of 0 left untitled.

Whether a title may be taken out of the body at all is a property of the record rather than of the search.
The record carries `title-source`, set where the record is built: `heading` when a heading opened the slide, `value` when a title was passed to `slide(...)`.
Only the first is taken out.

Reading it from the search instead was wrong, and quietly so.
An explicit slide's body is never split, so it may legitimately carry a heading at the record's own level; a renderer that looked for one would find it, place it as the title, discard the argument the author wrote and delete the heading from the body in the same move.
A record knows which it has, and a renderer looking at the body afterwards cannot.

A title that came from a value has no wrappers, so no `show heading` rule reaches it, and `state.title-source` passes that on so a theme can tell the two apart rather than discovering the difference.

## The slide record carries no `layout` key

The record in `src/core/record.typ` describes a slide with `kind`, `title`, `title-source`, `level`, `label`, `attrs` and `body`.
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

This ruling is about counters alone.
The label and footnote rules of specification 4.6 are separate mechanisms and are not covered here.

A counter of the author's own cannot be frozen: its updates are opaque content, so the count a relative shift needs cannot be taken from the body.
The same applies to anything numbered inside a `context` block, inside a `show` rule body, or by a `context-slide` callback, none of which the walk can see, and to a `set` rule written inside a slide body, since eligibility is read where the shift is written.

`counter(heading)` is hierarchical, so subtraction has no inverse for it.
A heading is kept from advancing instead, by a `set heading(numbering: none)` rule on the step pages that repeat it.

### What it costs

One walk of the slide body per slide, plus one walk per region resolved to `removed` on each step that removes it, both bounded by `MAX-DEPTH` and neither cached.
The walk is the one detection already makes, a removed region is a small subtree, and a count that is recomputed cannot go stale.

## A label survives on one step, chosen by where its element first shows

A slide body is emitted once per step, so every label on it is emitted once per step.
Typst accepts the duplicate and fails where one is referenced, so the deck builds until an author writes `@fig`.

### Decision

`rebuild` takes `keep-labels`, and every step but one is built with it `false`, which drops a label rather than reattaching it.
Carrying a label is a reason to rebuild in its own right, so the walk reaches a labelled element that has no marker near it.

The step that keeps a label is the first rendered step at which the element is shown, rather than the last.
A reference then lands where the thing it points at first appears.
Where no rendered step shows it, which a handout can produce, the first step that lays it out keeps it instead, since a label that exists nowhere fails a reference outright.

The splitter follows the same rule for a group a boundary cuts through, and puts the label on the first piece that carries something rather than on the first piece outright.
Within that piece it goes on the first node that carries something, since markup attaches a label to the last element of what it follows, and that is usually the space beside a boundary, which is merged away later.
The blank test is the one `slides` drops a lead-in segment by, so a piece one of them calls empty and the other does not cannot arise.

### Why not the last step

Specification 4.6 said the last step, which was written before the rule had to cover a slide title.
A title is shown on every step, so the last step would send a reference and an outline entry to the end of a slide's animation rather than to its start.

### What this does not cover

A label on the stepped region itself, as `#uncover("2-", [...]) <region>`, is refused: the marker is replaced by the content it resolves to, so no step could carry the label.

A label on a group nested inside a slide, where the group is flattened into the body around it, is lost by Typst's own content model rather than by this rule.
A label on an image cannot be dropped, since an image cannot be reconstructed, so a labelled image on a slide of several steps is refused.
A label a `context-slide` callback emits survives only on the step that keeps the labels of the region around it.

### What it costs

The reconstruction surface widens from the path to a marker to the path to a marker or a label, on every step but the one keeping the labels.
An unregistered container on such a path is a hard error where it was not one before, and the message says which of the two reasons brought the walk there.

## A hidden footnote is replaced rather than hidden

`hide` lays its content out, so a footnote behind a pause makes a real entry and the separator rule appears a step before the text that refers to it.
Typst offers no way to hide an entry.

### Decision

On a step where a region resolves to `hidden`, every footnote inside it is replaced by a hidden superscript of the number the footnote would have taken, followed by the advance the whole footnote would have made.

That advance is not the footnote counter alone.
A note body can number a figure or an equation of its own, and the slide's rewind subtracts every increment the body makes, so compensating one counter and not the others takes another below zero, which Typst refuses outright.

The replacement runs through `rebuild`, which takes a `match` argument for it, so both passes share one implementation rather than a second copy of the walk.
They remain two traversals: the footnote pass runs over each hidden region on each step that hides it, and its depth budget starts afresh, so it accepts nesting the first pass would have refused.
The pass runs over content that is already resolved, so it meets no marker.

Reconstruction widens again, as it did for labels: on a hidden step every element on the path to a footnote is rebuilt, so a footnote inside an unregistered container of the author's own is a hard error where the previous release laid it out.
`rebuild` takes a `subject` string so the message names what the walk was chasing, rather than reporting a step marker to an author who wrote none.

The size is measured rather than assumed: the mark and `super[1]` are both 3.38pt wide, and `super[10]` is 6.75pt, which is why the number matters.
`notes/counter-findings.md` records the measurements.

### What this does not cover

`footnote(<label>)` is left alone, since it makes no entry and advances nothing.

A label on a footnote survives on the step that shows it, which is the step that keeps the labels of the region around it.
Where a render puts only a hidden step on a page, the placeholder cannot carry the label, so that case is refused rather than dropped, which is the policy the label rule already follows.

A footnote written inside a `context` block is invisible to the traversal, so it is neither replaced nor counted, and its entry still appears early.

A footnote hidden on every step a render puts on a page, which `step(..., after: "hidden")` under a handout produces, is replaced on all of them: the counter advances although the note never appears, so the notes around it leave a gap.

The width the placeholder reserves is the default mark's, a superscript of the numbering, read from the footnote's own scheme when it sets one.
An author who restyles the mark with a `show` or `set` rule can still see a reflow when the note is revealed.

## An appendix is a switch, and the outline rules ride on the page

Specification 4.7 asks for three things a heading decides: a section slide is a PDF bookmark and a content slide is not, an appendix slide is excluded from the outline, and a slide is listed once however many steps it renders.

### Decision

All three are one computed `set heading(...)` rule per page, in `src/render/deck.typ`.
A step page that repeats a slide carries `numbering: none, outlined: false, bookmarked: false`, a content slide carries `bookmarked: false`, and an appendix slide carries both `outlined: false` and `bookmarked: false`.

Only what a page has to suppress is written, and a page with nothing to suppress carries no rule at all.
The rule sits inside the page body, so it wins over the document's own preamble: writing the permissive value would be the same statement to Typst and a different one to the author, quietly undoing a deck-wide `set heading(outlined: false)`.

Nothing is rebuilt and nothing is walked: the rule applies to whatever headings the page carries.
That is per page rather than per level, so every heading on a section slide is a bookmark, the title and anything written under it alike.
A divider carrying its own sub-heading is unusual, and the test pins the behaviour rather than claiming it cannot happen.

`#appendix` is a marker the splitter treats as a boundary and consumes, and every record after it carries `appendix: true`.
The switch fills the ordinary slide option, so the machine surface receives a dictionary rather than a second mechanism, and `slide-options(appendix: false)` on one of those slides wins over the switch.

### Why a switch rather than an option on each slide

An appendix is the tail of a deck rather than a property of one slide at a time, and Beamer and touying both read as a switch.
Writing the option on ten slides is ten chances to miss one, and a missed one is a slide in the outline that should not be there.

### What this does not cover

The logical slide number, the progress indicator and the `slide-number` token are M6's, with the chrome that reads them, so an appendix slide is excluded from the outline and from the bookmarks here and from the numbering there.

An appendix marker inside a block is refused, as a pause in that position is: the split examines top level children, and a marker it cannot reach would flag no slide at all.
One inside a `context` block is not refused and cannot be, since nothing there is reachable through `fields()`; the deck then builds with no appendix, exactly as a pause in that position is lost.

A second marker is refused rather than treated as a no-op: a deck has one appendix, and a marker that changed nothing is the silent no-op this package refuses everywhere else.

There is no marker that closes an appendix, and none is planned: an appendix runs to the end of the deck, and a slide that has to leave it says so with `slide-options(appendix: false)`.
