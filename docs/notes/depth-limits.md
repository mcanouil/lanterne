# Recursion depth limits

Why `MAX-DEPTH` in `src/core/walk.typ` is 30, measured rather than guessed.

Measured against typst 0.15.1 on 14 August 2026.
Re-measure after a Typst upgrade: the ceilings below are Typst's, not lanterne's, and nothing in the package pins them.

## What depth counts

One unit is one authored nesting level, meaning one content node the walk descends into.
Arrays do not count: a grid's `children` field holds an array of cells, and the array is a hop between two content nodes rather than a level of its own.
One exception: an array sitting directly inside another array does count, because that is no longer a hop between content nodes, and without it the walk recurses without bound through nesting made only of arrays.
A matrix pays one level for its rows, which is the only ordinary shape that reaches the exception.

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
The fixture's own `callout`, three blocks deep, holding a bullet list with `#strong` inside `#emph`, placed in a two column grid, measures **13** depth units.
Splitting adds one more, because `split-on` puts a preamble's rules back as a wrapper around each segment, so the same content reaches the walk at **14**.

Small changes to that shape move the figure by a unit or two, so treat it as roughly 15 rather than exactly 13.

## A subtree that is walked but never rebuilt

The budget also bounds detection over subtrees that hold no marker and are handed straight back.
That is not wasted: detection has to reach the bottom of a subtree to know there is no marker in it, and those frames sit on top of the rebuild frames already on the stack.

The two costs are not equal, and the trade is roughly linear.
With the guard lifted, a rebuild standing at depth `d` tolerates a marker-free tail of about `74 - 2d` units: 62 at depth 4, 44 at depth 10, 14 at depth 20.
One budget of 30 sits inside that surface everywhere it is reachable, which is why detection and reconstruction share a number rather than each carrying one.

## The choice

`MAX-DEPTH = 30`.

- Roughly twice the headroom over the deepest realistic content measured.
- Set against 38, the ceiling for a rebuild whose markers sit at a few levels, which is what real content looks like.

It is deliberately **not** set against 25, the marker-at-every-level ceiling.
Guarding that shape means rejecting content at 26 to 38 that Typst compiles without complaint, and a guard that rejects working decks is worse than one that misses a shape nobody writes.
A marker at every level of a tree that deep therefore still gets Typst's bare diagnostic.
No guard can prevent that: the limit is the interpreter's.

`has-marker` and `rebuild` both take `max-depth` for content that needs more, up to the ceilings above and no further.

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
  let reachable = f.values().filter(v => type(v) == content or type(v) == array)
  calc.max(..reachable.map(v => max-depth(v, d + 1)), d)
}
```

The filter matters.
Counting every field value, including lengths and colours, adds a unit at the bottom of each branch and over-states the depth the guard actually reaches.

That helper is itself recursive, so it cannot measure a tree near the ceiling.
Measure a short chain of the same shape and extrapolate: a marker at the bottom costs one unit per block, a marker at every level costs two.
