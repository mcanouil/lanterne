// Markers are metadata elements carrying a lanterne tag, so they are inert
// in output but findable by the traversal.

#import "../../src/core/marker.typ": (
  MARKER-PAUSE, MARKER-SLIDE-OPTIONS, is-marker, marker,
)

// Every declared kind must be constructible. An unknown kind panics, which no
// assertion in this file can catch, so it is compiled as its own case in
// tests/expect-fail/marker-unknown-kind.typ.
#assert(is-marker(marker(MARKER-SLIDE-OPTIONS)))

#let m = marker(MARKER-PAUSE)

#assert.eq(type(m), content)
#assert(is-marker(m))
#assert.eq(m.value.kind, MARKER-PAUSE)
#assert.eq(m.value.payload, (:))

#let m2 = marker(MARKER-PAUSE, payload: (index: 3))
#assert.eq(m2.value.payload.index, 3)

// Non-markers, including bare metadata, must not be mistaken for markers.
#assert(not is-marker([hello]))
#assert(not is-marker(metadata((kind: "pause"))))
#assert(not is-marker(42))

// is-marker is the predicate for a recursive fields() walk (tasks 6 and 8),
// so it must not error on any value the walk can hand it: none, arrays,
// dictionaries, strings, and content elements without a `value` field.
#assert(not is-marker(none))
#assert(not is-marker(()))
#assert(not is-marker((1, 2, 3)))
#assert(not is-marker((kind: "pause")))
#assert(not is-marker("pause"))
#assert(not is-marker(block[x]))
#assert(not is-marker(heading(level: 1)[x]))

marker tests passed.
