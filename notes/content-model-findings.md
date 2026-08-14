# Content model findings

Facts about Typst that the package depends on, established by probing rather than by reading.
Each one cost a wrong assumption at least once, and each is invisible from the documentation.

Measured against typst 0.15.1 on 14 August 2026, while building slide splitting and page emission.
Re-measure after a Typst upgrade: these are Typst's behaviours, not lanterne's, and nothing in the package pins most of them.

`notes/roundtrip-findings.md` covers reconstruction and the registry.
`notes/depth-limits.md` covers the recursion ceilings.
This note covers everything else.

## Element functions with no public binding

Three of the element functions the package has to name cannot be written down, and are obtained from a sample value in `src/utils/elements.typ`.

| Binding | Sample | `repr` |
| --- | --- | --- |
| `SEQUENCE` | `[*a* b].func()` | `sequence` |
| `STYLED` | `text(size: 12pt)[x].func()` | `styled` |
| `SPACE` | `[ ].func()` | `space` |

`[].func()` is `sequence`, not `space`: an empty content value is a sequence of no children.

## A heading reports its level under three names

There is no single field to read.

| Written as | `fields()` |
| --- | --- |
| `heading(level: 2)[A]` | `(level: 2, body: [A])` |
| `== A` | `(depth: 2, body: [A])` |
| `heading(offset: 1)[a]` | `(offset: 1, body: [a])` |

The third carries neither `level` nor `depth`, because the depth it is added to is the default of 1, so its real level is 2 and a reader defaulting `depth` to 0 gets 1.
`src/core/slides.typ` reads `level`, then `depth` defaulted to 1 plus `offset` defaulted to 0.

An offset set by a rule is not reachable at all.
`#set heading(offset: 1)` lives in the style wrapper's `styles`, and Typst exposes no way to read a wrapper's rules, so a heading under one reports the level it was written at and renders at another.

## Markup arrives as a nested sequence

`#include "part.typ"`, a `#let` fragment and a helper's return value all land as a single `sequence` among the body's children rather than as their own children.

```typst
[== First

a

#include "part.typ"].children  // ("heading", "parbreak", "text", "parbreak", "sequence")
```

A splitter that treats a nested sequence as opaque therefore finds no boundary inside any of the three, which collapses a deck written across several files onto one slide.

Adjacent plain text merges instead: `[a #[b c] d].children` is five text and space elements, with no sequence among them, so the group only survives as a sequence when it holds something that cannot merge.

## Pages

`page(...)` called several times in a row emits exactly that many pages.
There is no leading blank page and no trailing one, so a page count is a faithful check on an emitter.

`page.paper` cannot be read in a `context` block: the field does not exist on the element function, and only the dimensions it resolved to are readable.
Read `page.width` and `page.height` instead, and compare a ratio rather than an exact length.

| Paper | Width | Height |
| --- | --- | --- |
| `presentation-16-9` | 841.89pt | 473.56pt |
| `presentation-4-3` | 793.7pt | 595.28pt |

`set document(...)` must be evaluated before any page is opened, since Typst resolves the document's own properties once and before it lays anything out.

## Show rules cannot observe what they are about to produce

Inside `show heading: it => ...`, `text.size` read from a `context` block is the size in force around the heading, not the size the rule is setting.
A rule that sets a size and asserts that size inside itself fails, and the assertion has to be made against the helper that computes it.

## References need numbering

`@label` on a heading fails with `cannot reference heading without numbering`, whatever the label is attached to.
Specification 4.7 says Typst 0.15 creates named destinations for labelled headings, which is true and is not sufficient on its own: a deck that sets no `heading(numbering: ...)` can be linked into with `link(<label>)` but not referenced with `@label`.

A heading re-emitted outside the style wrapper carrying `#set heading(numbering: "1.")` is not numbered, so the reference fails even where the author did set numbering.
That is why the heading opening a slide is left where it was written.

## Labels are invisible to equality

Content equality ignores labels, so a rebuild, a split or a re-emission that drops every label passes every equality assertion in the suite.
Every place the package touches a label asserts the label itself rather than comparing content: `tests/unit/test-walk-rebuild.typ`, `tests/unit/test-split.typ` and `tests/unit/test-slides.typ` each carry such an assertion, and each says why.

## Tooling

`typst query` is deprecated in 0.15.1 and prints a warning naming its replacement:

```sh
typst eval 'query(<label>).map(it => it.value)' --in file.typ
```

Specification 4.8 describes extracting the pdfpc entries with `typst query`, and that instruction is stale rather than wrong: the subcommand still works and warns.
