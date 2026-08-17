#import "/src/core/expand.typ": expand
#import "/src/core/range.typ": parse-range
#import "/src/core/steps.typ": context-slide, dim, focus, only, pause, uncover

// A dim renderer stands in for the theme's, which src/core never reads. `emph`
// rather than a text wrapper such as `[DIM(#body)]`, because interpolating
// content into markup builds a sequence of separate text elements and comparing
// it against a literal string never holds.
#let mark-dim = body => emph(body)

// A body with no step is one step.
#assert.eq(expand([a], mark-dim).total, 1)
#assert.eq(expand([a], mark-dim).steps.len(), 1)
#assert.eq(expand([a], mark-dim).steps.first().index, 1)

// Two pauses are three steps.
#assert.eq(expand([a #pause b #pause c], mark-dim).total, 3)

// An open ended range extends the count to its start. This is the case a wrong
// counting rule renders as nothing at all, so it is asserted on its own.
#let counted = expand([a #uncover("3-", [c])], mark-dim)
#assert.eq(counted.total, 3)

// The steps option raises the count and never lowers it.
#assert.eq(expand([a #pause b], mark-dim, steps: 5).total, 5)
#assert.eq(expand([a #pause b #pause c], mark-dim, steps: 2).total, 3)

// A step inside a step is counted, because the walk descends into a payload.
// The count alone would still pass if the inner rebuild were deleted, so the
// resolved body of every step is pinned as well, which the composition of the
// two ranges is not.
#let nested = expand([#uncover("2-", [b #uncover("4-", [d])])], mark-dim).steps
#assert.eq(nested.len(), 4)
#assert.eq(nested.at(0).body, hide([b #hide([d])]))
#assert.eq(nested.at(1).body, [b #hide([d])])
#assert.eq(nested.at(2).body, [b #hide([d])])
#assert.eq(nested.at(3).body, [b #[d]])

// The four states, read off the resolved bodies. `hide` reserves space and
// leaves the content in the tree, so the assertion compares against hide of the
// same content rather than against nothing.
#let states = expand([#uncover("2", [x])], mark-dim).steps
#assert.eq(states.at(0).body, hide([x]))
#assert.eq(states.at(1).body, [x])

#let removed = expand([#only("2", [x])], mark-dim).steps
#assert.eq(removed.at(0).body, [])
#assert.eq(removed.at(1).body, [x])

// dim itself, not merely mark-dim standing in for it, resolves through expand:
// dimmed before its range and full strength inside and after it.
#let dimmed = expand([#dim("2", [x])], mark-dim).steps
#assert.eq(dimmed.at(0).body, emph([x]))
#assert.eq(dimmed.at(1).body, [x])

// focus is dimmed on both sides, so the dim renderer is called before and after
// the range and not inside it.
#let focused = expand([#focus("2", [x])], mark-dim).steps
#assert.eq(focused.at(0).body, emph([x]))
#assert.eq(focused.at(1).body, [x])

// The callback is handed the resolved index and total. It branches on both
// rather than printing them, since content interpolated into markup builds a
// sequence of text elements that no literal compares equal to.
#let reporter = (index, total) => if index == total { strong([last]) } else { emph([more]) }
#let called = expand([#context-slide(reporter)], mark-dim, steps: 2)
#assert.eq(called.steps.at(0).body, emph([more]))
#assert.eq(called.steps.at(1).body, strong([last]))

// A stepped region returned by a callback resolves per step, rather than
// passing through untouched: the callback's result goes through the same
// rebuild pass as the rest of the body.
#let inner-region = expand(
  [#context-slide((index, total) => [#uncover("2-", [INNER])])],
  mark-dim,
  steps: 3,
).steps
#assert.eq(inner-region.at(0).body, hide([INNER]))
#assert.eq(inner-region.at(1).body, [INNER])
#assert.eq(inner-region.at(2).body, [INNER])

// keep selects which steps are resolved while total still reports them all, so
// a callback on a handout is handed the same total as on the full deck.
#let final = expand([a #pause b #pause c], mark-dim, keep: "final")
#assert.eq(final.total, 3)
#assert.eq(final.steps.len(), 1)
#assert.eq(final.steps.first().index, 3)

#let selected = expand([a #pause b #pause c], mark-dim, keep: parse-range("1-2", "t"))
#assert.eq(selected.total, 3)
#assert.eq(selected.steps.map(part => part.index), (1, 2))

// A handout selection never empties a slide: when it selects no step, the
// slide renders its final step instead of nothing at all.
#let empty-one-step = expand([a], mark-dim, keep: parse-range("2-", "t"))
#assert.eq(empty-one-step.total, 1)
#assert.eq(empty-one-step.steps.map(part => part.index), (1,))

#let empty-three-step = expand([a #pause b #pause c], mark-dim, keep: parse-range("9-", "t"))
#assert.eq(empty-three-step.total, 3)
#assert.eq(empty-three-step.steps.map(part => part.index), (3,))

// An ordinary selection is unaffected by the fallback above: it still selects
// exactly the steps its spans cover.
#let ordinary = expand([a #pause b #pause c], mark-dim, keep: parse-range("2-", "t"))
#assert.eq(ordinary.total, 3)
#assert.eq(ordinary.steps.map(part => part.index), (2, 3))

// A pause reveals what follows it, so the first step hides the second segment
// and the last shows both. Written without spaces around the pause and with an
// element per segment, so the assertion compares structure rather than the
// space elements markup inserts between children.
#let paused = expand([#emph[a]#pause#strong[b]], mark-dim).steps
#assert.eq(paused.at(0).body, [#emph[a]#hide(strong[b])])
#assert.eq(paused.at(1).body, [#emph[a]#strong[b]])

// A step inside a registered container is resolved rather than lost, which is
// the traversal guarantee this milestone finally exercises.
#assert.eq(expand([#block[#only("2", [x])]], mark-dim).steps.first().body, [#block[]])
