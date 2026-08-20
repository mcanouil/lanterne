# Emit surface spike

Throwaway, by the specification's own instruction.

Section 12.2 asks for a Lua filter mapping Reveal's `. . .` and `::: {.incremental}` onto `emit-step`, and gives the reason: the emission contract of section 3.2 is the part most likely to be wrong, and it was specified before it had a caller.
This is that caller.
It exists to be run and read, not shipped, and it is deleted when the real extension begins after M9.

```sh
tools/quarto-filter-spike/run.sh
```

The deck renders ten pages: two steps on the first slide, four on the second and four on the third.

## What it falsified

Nothing in `emit-step`.
The surface took everything a filter needed to emit, and no argument of it changed.

What the spike did falsify is the mapping around it, and the assumptions the follow-up extension would otherwise have carried into its first week.

### The mapping cannot live in Typst

Quarto's Typst writer drops a Div's classes.
`::: {.incremental}` reaches the `.typ` as a bare `#block[...]`, as `tests/fixtures/quarto-deck.typ` shows, so nothing downstream can tell it from any other block.
Anything mapping Reveal's syntax has to run before that writer, which makes it a Pandoc filter rather than a Typst one.

### A filter brackets a body, it cannot pass one

`emit-step` is called by emitting raw Typst before and after the item's own blocks, because a filter cannot serialise Pandoc blocks to Typst without invoking the writer it runs before.

That works only because `body` is a named argument taking content, so an open bracket and a close bracket are a legal call.
A surface that took its body as a string, or positionally, would have been unusable here.
This is the constraint section 3.2 was right to impose without knowing why.

### The step goes inside the list item

Section 14 maps `::: {.incremental}` to "per list item `emit-step`", which reads two ways.
Wrapping each item turns a three-item list into three unrelated blocks and the bullets are gone: the reader sees three sentences appear in turn, with no list left.
Wrapping the item's contents keeps the list.

The mapping table should say so.

An item whose body is hidden still shows its bullet, which is Reveal's behaviour too, and the mechanism section 4.4 already records for a stepped region inside a list item.

### The heading shift makes every slide a section slide

Quarto renders Typst with `--shift-heading-level-by=-1`, because the document title is the level 1 heading.
Under that shift a `##` slide heading arrives as level 1, which is below the default slide level, so every slide becomes a section slide and centres its body.

An extension has to undo the shift or set `slide-level` to match it.
This is not in section 14, and it costs a confusing render to find.

### The package has to be inside the render root

Typst refuses an import above its root, and Quarto sets that root to the rendered document's own directory.
Neither `/lib.typ` nor `../../lib.typ` resolves from a deck rendered anywhere but the package itself.

Specification section 11 already requires the follow-up extension to vendor lanterne under `_extensions/<name>/typst/packages`.
That requirement is load-bearing rather than tidiness, and this is why.

### Pandoc interpolates Typst comments

A template variable named inside a `//` comment is substituted like any other.
A comment mentioning the body placeholder therefore has the whole document pasted into it, and everything below it, imports included, lands after the body.

## Files

| File | What it is |
| --- | --- |
| `deck.qmd` | The fixture: a pause, an incremental list, and the two together. |
| `filter.lua` | The mapping, as a Pandoc filter. |
| `template.typ` | The Pandoc template, standing in for a real extension's typst-show partial. |
| `run.sh` | Convert, then compile against the package. |

The committed fixture under `tests/fixtures/` is not used here.
It is Quarto output kept verbatim as evidence, it carries no `. . .`, and its `.typ` imports `@preview/fontawesome`, which this package refuses to depend on.
Regenerating it to add a pause would mean reconciling `tests/unit/test-quarto-fixture.typ` against a new render, which is a separate act with its own reasons.
