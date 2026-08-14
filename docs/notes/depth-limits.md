# Recursion depth limits

Why `MAX-DEPTH` in `src/core/walk.typ` is 20, measured rather than guessed.

Measured against typst 0.15.1 on 14 August 2026.
Re-measure after a Typst upgrade: the ceilings below are Typst's, not lanterne's, and nothing in the package pins them.

## What depth counts

One unit is one authored nesting level, meaning one content node the walk descends into.
Arrays do not count: a grid's `children` field holds an array of cells, and the array is a hop between two content nodes rather than a level of its own.

This is a correction.
The first implementation counted every `fields()` hop, which cost about three units per authored level, so a limit of 24 hit at roughly eight levels and the number in the error message meant nothing to the author reading it.

## Typst's ceilings

Each figure is the deepest chain that compiles.
One deeper aborts with `maximum function call depth exceeded`, reported from inside `walk.typ` with no source location for the offending content, which is the diagnostic the guard exists to replace.

The probe nests `block` elements, either with a single marker at the bottom or with one at every level, and runs with the guard raised out of the way, `max-depth: 100000`.

| Walk | Shape | Deepest authored blocks | Deepest depth units |
| --- | --- | --- | --- |
| `has-marker` | marker at the bottom | 76 | 77 |
| `has-marker` | marker at every level | 19 | 39 |
| `rebuild` | marker at the bottom | 37 | 38 |
| `rebuild` | marker at every level | 12 | 25 |

A marker at every level costs two depth units per authored block, because the marker makes the block's body a sequence, and it is the expensive case in both walks: the detection call at each level cannot short-circuit its way out of the subtree below it.

`rebuild` is the stricter walk and sets the budget.
Every level of a rebuild pays for a detection call as well, so the two limits are not independent and a single number governs both.

## The realistic case

The shape the limit has to clear is generated content, not a hand-written torture test.
A two column grid holding a callout block, itself three blocks deep, with a nested bullet list and `#strong` inside `#emph`, measures **14** depth units.

## The choice

`MAX-DEPTH = 20`.

- Six units of headroom over the deepest realistic content measured.
- Five units under the worst measured ceiling, 25, so lanterne's message arrives before Typst's.

`has-marker` and `rebuild` both take `max-depth` for content that needs more.
Raising it works up to Typst's ceiling and no further: past roughly 25 units a marker-dense tree gets the bare diagnostic back, because no guard can lift a limit imposed by the interpreter.

## Method

`typst compile` each candidate depth and binary search the largest that exits zero.

```typst
#let nest(k, every) = {
  let acc = marker(MARKER-PAUSE)
  for _ in range(k) { acc = if every { block(acc + marker(MARKER-PAUSE)) } else { block(acc) } }
  acc
}
```

Depth units are counted with the same rule the walk uses, content nodes only:

```typst
#let max-depth(node, d) = {
  if type(node) == array {
    if node.len() == 0 { return d }
    return calc.max(..node.map(c => max-depth(c, d)))
  }
  if type(node) != content { return d }
  let f = node.fields()
  if f.len() == 0 { return d }
  calc.max(..f.values().map(v => max-depth(v, d + 1)))
}
```

That helper is itself recursive, so it cannot measure a tree near the ceiling.
Measure a short chain of the same shape and extrapolate: a marker at the bottom costs one unit per block, a marker at every level costs two.
