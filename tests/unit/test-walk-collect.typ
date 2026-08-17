#import "/src/core/marker.typ": MARKER-PAUSE, marker
#import "/src/core/walk.typ": collect-markers, has-element, has-marker

#let m = marker(MARKER-PAUSE)

// Every marker is reported, not merely the first, and a marker nested in a
// registered container is reached.
#assert.eq(collect-markers([a #m b #m]).len(), 2)
#assert.eq(collect-markers([#block[#m]]).len(), 1)
#assert.eq(collect-markers([a b]).len(), 0)

// A marker inside another marker's payload is reported as well, because a step
// written inside a step has to be counted.
#let nested = marker(MARKER-PAUSE, payload: (body: [x #m y]))
#assert.eq(collect-markers(nested).len(), 2)

// What comes back is the marker itself, so a caller reads its payload.
#assert.eq(collect-markers([a #m]).first(), m)

// The order is the order the walk reaches them, not merely their count: two
// markers with different payloads come back first before second.
#let first = marker(MARKER-PAUSE, payload: (n: 1))
#let second = marker(MARKER-PAUSE, payload: (n: 2))
#assert.eq(collect-markers([#first #second]), (first, second))

// has-marker still answers the question it always did.
#assert.eq(has-marker([#block[#m]]), true)

// has-element asks the same walk a different question, which is what the
// heading guard needs.
#assert.eq(has-element([a #heading(level: 3)[t] b], heading), true)
#assert.eq(has-element([#block[#list[#heading(level: 3)[t]]]], heading), true)
#assert.eq(has-element([a b], heading), false)
#assert.eq(has-element([#m], heading), false)
