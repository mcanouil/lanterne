#import "/src/core/counters.typ": advance, increments, rewind
#import "/src/core/marker.typ": MARKER-STEP, marker
#import "/src/core/range.typ": parse-range

// A body that numbers nothing advances nothing.
#assert.eq(increments([]), (figures: (), equations: (styled: 0, forced: 0), footnotes: 0))
#assert.eq(increments([plain text]).figures, ())

// A figure with no kind of its own is an image figure, which is what Typst
// infers for any body that is not a table or a raw block.
#assert.eq(
  increments([#figure(rect(), caption: [c])]).figures,
  ((kind: image, styled: 1, forced: 0),),
)

// The kind is inferred from the body rather than from the top node, because
// Typst sees through a wrapper: figure([#table(...)]) is a table figure.
#assert.eq(increments([#figure(table(columns: 1, [x]))]).figures.first().kind, table)
#assert.eq(increments([#figure([#table(columns: 1, [x])])]).figures.first().kind, table)
#assert.eq(increments([#figure(raw("code"))]).figures.first().kind, raw)
#assert.eq(increments([#figure([#raw("code")])]).figures.first().kind, raw)

// A body holding both takes the kind of whichever comes first, which is what
// Typst does: reading the table first would shift a counter the caption never
// draws its number from.
#assert.eq(
  increments([#figure([#table(columns: 1, [x]) #raw("code")])]).figures.first().kind,
  table,
)
#assert.eq(
  increments([#figure([#raw("code") #table(columns: 1, [x])])]).figures.first().kind,
  raw,
)

// A kind written on the call is read as it stands, whether a string or an
// element function, since each has a counter of its own.
#assert.eq(increments([#figure(circle(), kind: "custom")]).figures.first().kind, "custom")
#assert.eq(increments([#figure(circle(), kind: table)]).figures.first().kind, table)

// Two kinds are counted separately, in the order the walk reaches them.
#assert.eq(
  increments([#figure(rect()) #figure(table(columns: 1, [x])) #figure(rect())]).figures,
  ((kind: image, styled: 2, forced: 0), (kind: table, styled: 1, forced: 0)),
)

// An instance that carries its own numbering is counted apart from one that
// takes it from the style, because only the second depends on a set rule.
#assert.eq(
  increments([#figure(rect(), numbering: "1")]).figures,
  ((kind: image, styled: 0, forced: 1),),
)

// An instance numbered none never advances its counter, so it is not counted
// at all.
#assert.eq(increments([#figure(rect(), numbering: none)]).figures, ())

// A block equation advances the equation counter and an inline one does not.
#assert.eq(increments($ x = 1 $).equations, (styled: 1, forced: 0))
#assert.eq(increments($x = 1$).equations, (styled: 0, forced: 0))
#assert.eq(
  increments(math.equation(block: true, numbering: "(1)", $x$)).equations,
  (styled: 0, forced: 1),
)
#assert.eq(increments(math.equation(block: true, numbering: none, $x$)).equations, (styled: 0, forced: 0))

// A footnote always advances its counter: Typst rejects a numbering of none
// for one, so there is nothing to read from the style.
#assert.eq(increments([a#footnote[n] b#footnote[m]]).footnotes, 2)

// The walk reaches a numbered element wherever it sits, including inside a
// container and inside a step marker's payload, since a figure behind an
// uncover advances the counter exactly as one in plain body does.
#assert.eq(increments([#block[#figure(rect())]]).figures.first().styled, 1)
#let stepped = marker(
  MARKER-STEP,
  payload: (spans: parse-range("2-", "test"), before: "hidden", after: "visible", body: [#figure(rect())]),
)
#assert.eq(increments(stepped).figures.first().styled, 1)

// Both shifts are content, and a body that numbers nothing produces none of
// it, so a static slide carries no freezing machinery at all.
#assert.eq(type(rewind(increments([#figure(rect())]))), content)
#assert.eq(type(advance(increments([#figure(rect())]))), content)
#assert.eq(rewind(increments([])), [])
#assert.eq(advance(increments([])), [])
