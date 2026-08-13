// Markers are metadata elements carrying a lanterne tag, so they are inert
// in output but findable by the traversal.

#import "../../src/core/marker.typ": (
  MARKER-PAUSE, is-marker, marker,
)

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

marker tests passed.
