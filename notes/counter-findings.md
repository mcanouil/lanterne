# Counter findings

## Verdict

**A counter cannot be frozen by capturing it.**
Reading a counter with `get` at the start of a slide, keeping the value in a `state`, and putting it back on the next step does not converge.
The captured value is introspective and reaches the next slide through document state, so the information advances about one slide per layout run, and Typst allows five.

Three stepped slides are already enough.
The compile emits `value of state did not converge` with the observed values `()`, `((0,))`, `((4,))`, `((1,))`, `((3,))` and a final value of `((2,))`, and the pages render the same figure as 3 on one step and 2 on the next.
Thirty slides emit 118 warnings.
Worse, the document still exits zero, so both check harnesses reported a pass until `tools/check.sh` was taught that a warning is a failure.

What does hold is arithmetic on the body rather than a reading of the counters.
The number of increments a body makes is counted from the body itself, every step after the first rewinds by that count, and a region that resolves to `removed` advances by its own count in place.
Every step then makes the same increments and numbers identically.
Ten stepped slides compile with nothing on stderr.

## The compiler floor

`typst.toml` pins `compiler = "0.15.0"`, one patch below the version everything here was characterised on, exactly as `notes/roundtrip-findings.md` records for the registry.

Re-run the suite on the floor whenever the pin moves or a rule here changes.

## Method

Probed against `typst 0.15.1`.

Each rule was established by compiling a document that exercises it and reading the counter back with `counter(...).at(location)`, rather than by reading the caption Typst drew.
A caption is drawn from the counter of the figure's kind, so a probe that reads `counter(figure)` measures a counter no reader ever sees, which is how the first version of the default frozen set came to name it.

Every warning quoted here is the verbatim first line of the Typst diagnostic.

## Which counter a reader sees

**A figure is numbered through the counter of its kind, never through `counter(figure)`.**

One document containing four figures produced four distinct counters:

| Figure | Counter |
| --- | --- |
| `figure(rect(), caption: [i])` | `counter(figure.where(kind: image))` |
| `figure(table(...), caption: [t])` | `counter(figure.where(kind: table))` |
| `figure(raw(...), caption: [r])` | `counter(figure.where(kind: raw))` |
| `figure(circle(), kind: "custom", ...)` | `counter(figure.where(kind: "custom"))` |

Freezing `counter(figure)` alone leaves every caption number re-incrementing, while a probe that reads `counter(figure)` reports success.

`table` has no counter of its own in Typst, so the specification's original frozen set named a counter that does not exist.

## When a counter advances

| Element | Advances |
| --- | --- |
| `figure` | Unless its effective numbering is `none`. Typst's default is `"1"`, so a figure numbers unless something turns it off. |
| `figure` with no caption | Yes. A caption is not what advances the counter. |
| `math.equation` | Only when it is block level and its effective numbering is not `none`. Typst's default is `none`, so an equation numbers only under a set rule or its own argument. |
| `math.equation`, inline | Never. |
| `footnote` | Always. Typst rejects `set footnote(numbering: none)` with `expected string or function, found none`, so there is no case to read. |
| `heading` | Only when numbered, and Typst's default is `none`. |
| Anything inside `hide()` | Yes. Hidden content is laid out, so it numbers. |
| Anything inside a region resolved to `removed` | No. It is not laid out at all. |

An instance that carries its own `numbering` overrides the set rule in both directions: `figure(..., numbering: none)` under `set figure(numbering: "1")` does not advance, and `figure(..., numbering: "1")` under `set figure(numbering: none)` does.
This is why `src/core/counters.typ` counts the two apart: an instance that sets its own numbering is known at count time, and one that inherits has to be read from the style at render time.

Reading a style inside `context` is safe, unlike reading a counter: `figure.numbering`, `math.equation.numbering` and `heading.numbering` are all readable there and feed no convergence loop.

## How a figure's kind is decided

`kind: auto`, which is the default, is resolved from the body, and Typst sees through a wrapper.

| Body | Kind |
| --- | --- |
| `table(...)` | `table` |
| `[#table(...)]` | `table` |
| `raw(...)` or `[#raw(...)]` | `raw` |
| `rect()`, plain text, a grid, a box | `image` |
| `[#table(...) #raw(...)]` | `table` |
| `[#raw(...) #table(...)]` | `raw` |

So anything that is neither a table nor a raw block is an image figure, and the inference has to search the body rather than test the top node.

The last two rows were measured rather than assumed, and they overturned the first version of this rule.
A body holding both takes the kind of whichever comes first, so an inference that always preferred the table would shift `counter(figure.where(kind: table))` while the caption drew its number from the raw counter, leaving both wrong.

A `kind` written on the call is read as it stands, whether a string or an element function.
A `kind` set by a `set` rule is not readable: it lives in the style wrapper, which Typst exposes no way to inspect, exactly as `notes/content-model-findings.md` records for a heading offset.

## The heading counter is not shifted

`counter(heading)` is hierarchical, and a hierarchical counter cannot be rewound by subtraction: an increment at one level truncates the levels below it, so the operation has no inverse.

A heading is therefore kept from advancing rather than put back, by a `set heading(numbering: none)` rule on every step page that repeats it.
That costs nothing a reader sees, because a heading advances only when numbered, and this renderer draws a slide title from `it.body`.

The rule covers the counter alone today.
A repeated step page still emits its heading, so an outline still lists a stepped slide once per step and the PDF still carries a bookmark for each.
`outlined: false` and `bookmarked: false` belong on the same rule and arrive with the outline and bookmark work.

## The footnote placeholder

A footnote inside a region resolved to `hidden` still makes its entry, because `hide` lays its content out.
The separator rule and the note therefore appear a step before the text that refers to them.

Typst offers no way to hide an entry, so the footnote is replaced on those steps.
What stands in for it is measured rather than guessed:

| Content | Width |
| --- | --- |
| `footnote[x]`, the mark | 3.38pt |
| `super[1]` | 3.38pt |
| `hide(super[1])` | 3.38pt |
| `super[10]` | 6.75pt |

So the mark is a superscript of the numbering, and a hidden superscript of the same number occupies the same space.
A two digit number is wider, which is why the placeholder carries the number the footnote would have taken rather than a fixed digit.
That number is read from the live counter at the point the placeholder sits, which is a read of document state rather than a write, so it feeds no convergence loop.

The placeholder then advances the footnote counter by one, exactly as the footnote would have, so the notes after it keep their numbers and the slide's rewind still balances.

`footnote(<label>)` is left alone: it is a second reference to a note that already exists, so it makes no entry and advances nothing.

## Two cases that need no compensation

**An enum item inside an `only` region keeps its number.**
The marker sits inside the item's body, so a step that drops the region drops the body and leaves the item, and the numbering of the items after it is unchanged.
The dropped step shows an empty marker, which is cosmetic.

**A citation cannot renumber between steps.**
A numeric style numbers a bibliography entry once for the whole document, so the same citation carries the same number on every page.
The order in which entries are first cited can differ from a deck with no steps, but it cannot differ between two steps of one slide.

## What is not counted

Content inside a `context` block, inside a `show` rule body, or returned by a `context-slide` callback is not visible to the walk, so what it numbers is neither counted nor compensated.
This is the same blindness the traversal already documents for a step marker, and specification 4.4 carries a row for it.

A `set` rule written inside a slide body is not read either.
Eligibility is read where the shift is written, so only the numbering in force there is honoured: a `set figure(numbering: none)` half way down a slide leaves those figures counted as though they numbered, and the rewind then subtracts increments that never happened.
Write such a rule outside the deck.

The two shifts also read the style at two different points.
A rewind reads it at the head of a step page, and the advance for a removed region reads it where the region stood, so a `set` rule written between the two makes the pair disagree.

The read is per family rather than per figure kind, so a rule that turns numbering off for one kind alone, such as `show figure.where(kind: table): set figure(numbering: none)`, is invisible to it: those figures are counted and rewound although they advance nothing.
Turn numbering off for the deck rather than for one kind, or set `numbering: none` on the figures themselves, which is read per instance and is exact.

A counter of the author's own cannot be frozen at all.
Its updates are opaque content, and a relative shift needs a count that only the author can supply.
A `state` of the author's own cannot be frozen either, and for the reason the whole capture approach failed: a state holds an arbitrary value, so putting one back needs the introspective read that does not converge, and an arbitrary update cannot be inverted.
`frozen-counters` and `frozen-states` are therefore dropped from specification 4.6 rather than deferred.

## What it costs

The count is a walk of the slide body, once per slide, plus one walk per region that resolves to `removed`, on every step that removes it.
Both are bounded by `MAX-DEPTH` and neither is cached.

This is accepted rather than optimised.
The walk is the same one detection already makes for every step, a removed region is a small subtree by construction, and a count that is recomputed cannot go stale.

## Regression guard

`tests/unit/test-counters.typ` pins the counting rules above, one assertion per row.

`tests/unit/test-freezing.typ` pins what a reader sees, by querying the rendered document rather than by comparing content: a figure behind a pause, a figure after an `only` region, the slide that follows them, an equation, a footnote, and a static slide that must be left alone.
Removing either half of the mechanism changes those numbers, which is what the test detects.

`tests/expect-warn/state-does-not-converge.typ` keeps the rejected mechanism in the build as the thing it is: a document that compiles and warns.
