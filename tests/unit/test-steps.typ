#import "/src/core/marker.typ": MARKER-CONTEXT-SLIDE, MARKER-PAUSE, MARKER-STEP, is-marker
#import "/src/core/range.typ": max-mentioned
#import "/src/core/steps.typ": context-slide, dim, focus, only, pause, step, uncover
#import "/src/emit/step.typ": emit-step

// A stepped region is a marker carrying its spans, its two states and its body.
#let region = step("2-", [x])
#assert.eq(is-marker(region), true)
#assert.eq(region.value.kind, MARKER-STEP)
#assert.eq(region.value.payload.spans, ((from: 2, to: none),))
#assert.eq(region.value.payload.before, "hidden")
#assert.eq(region.value.payload.after, "visible")
#assert.eq(region.value.payload.body, [x])

// The integer form is the one step it names.
#assert.eq(step(2, [x]).value.payload.spans, ((from: 2, to: 2),))

// The multi-span form the module header motivates: a set of steps, not an
// interval, so it normalises to one span per entry.
#assert.eq(
  step((1, 3, 5), [x]).value.payload.spans,
  ((from: 1, to: 1), (from: 3, to: 3), (from: 5, to: 5)),
)

// pause is tagged MARKER-PAUSE specifically, so a wrong kind constant cannot
// pass.
#assert.eq(pause.value.kind, MARKER-PAUSE)

// A closed upper bound still raises the step count to its end, on both
// uncover and dim, even though the content already reads as visible there.
// See the docstrings above.
#assert.eq(max-mentioned(uncover("2-4", [x]).value.payload.spans), 4)
#assert.eq(max-mentioned(dim("2-4", [x]).value.payload.spans), 4)

// The four aliases are the one primitive with the two states set. Beamer needs
// three primitives for this; the states are what collapse them into one.
#assert.eq(uncover("2", [x]), step("2", [x], before: "hidden", after: "visible"))
#assert.eq(only("2", [x]), step("2", [x], before: "removed", after: "removed"))
#assert.eq(dim("2", [x]), step("2", [x], before: "dimmed", after: "visible"))
#assert.eq(focus("2", [x]), step("2", [x], before: "dimmed", after: "dimmed"))

// A pause is content, so #pause reads as the specification writes it.
#assert.eq(is-marker(pause), true)

// The callback form carries the closure the resolution calls.
#let callback = context-slide((index, total) => [#index of #total])
#assert.eq(callback.value.kind, MARKER-CONTEXT-SLIDE)
#assert.eq(type(callback.value.payload.fn), function)

// The stored callback is callable as fn(index, total). It branches on both
// arguments and returns a distinguishable element, rather than interpolating
// them into markup: content interpolated into markup builds a sequence of
// separate text elements that no literal compares equal to.
#let reporter = context-slide(
  (index, total) => if index == total { strong([last]) } else { emph([more]) },
)
#assert.eq((reporter.value.payload.fn)(1, 2), emph([more]))
#assert.eq((reporter.value.payload.fn)(2, 2), strong([last]))

// Delegation: the machine surface and the ergonomic surface converge on one
// primitive, so they build the same content rather than two implementations
// that can drift.
#assert.eq(emit-step(range: "2-", body: [x]), step("2-", [x]))
#assert.eq(
  emit-step(range: "2", before: "removed", after: "removed", body: [x]),
  only("2", [x]),
)
