#import "/src/core/range.typ": first-step, in-spans, max-mentioned, parse-range

// An integer is the one step it names.
#assert.eq(parse-range(3, "t"), ((from: 3, to: 3),))

// An array is one span per entry, since it is a set of steps and not an
// interval.
#assert.eq(parse-range((1, 3, 5), "t"), ((from: 1, to: 1), (from: 3, to: 3), (from: 5, to: 5)))

// The four string forms.
#assert.eq(parse-range("2", "t"), ((from: 2, to: 2),))
#assert.eq(parse-range("2-", "t"), ((from: 2, to: none),))
#assert.eq(parse-range("-3", "t"), ((from: 1, to: 3),))
#assert.eq(parse-range("2-4", "t"), ((from: 2, to: 4),))

// Membership, one based.
#assert.eq(in-spans(parse-range("2-4", "t"), 1), false)
#assert.eq(in-spans(parse-range("2-4", "t"), 2), true)
#assert.eq(in-spans(parse-range("2-4", "t"), 4), true)
#assert.eq(in-spans(parse-range("2-4", "t"), 5), false)
#assert.eq(in-spans(parse-range("2-", "t"), 99), true)
#assert.eq(in-spans(parse-range((1, 3), "t"), 2), false)

// The lowest step mentioned, which is where the before zone ends.
#assert.eq(first-step(parse-range("2-4", "t")), 2)
#assert.eq(first-step(parse-range((5, 3), "t")), 3)

// The highest step mentioned. An open end contributes its start and nothing
// beyond it: uncover("3-") on a slide with no pause must still render three
// steps, and a rule that counted an open end as zero renders nothing at all.
#assert.eq(max-mentioned(parse-range("2-4", "t")), 4)
#assert.eq(max-mentioned(parse-range("3-", "t")), 3)
#assert.eq(max-mentioned(parse-range("-3", "t")), 3)
#assert.eq(max-mentioned(parse-range((1, 7, 3), "t")), 7)
