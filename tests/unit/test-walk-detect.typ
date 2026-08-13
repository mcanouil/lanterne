// Detection is generic and total: a marker is found inside any element,
// registered or not, so it can never be silently dropped.
//
// fields() is readable on every element (see docs/notes/roundtrip-findings.md),
// and field values can be content, arrays of content, or arrays of arrays.
// The traversal has to recurse into all of those shapes, not just a flat
// array of content, or a marker buried in a container field goes unseen.

#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/walk.typ": has-marker

#let m = marker(MARKER-PAUSE)

#assert(has-marker(m))
#assert(has-marker([before #m after]))
#assert(has-marker(block[#m]))
#assert(has-marker(block(box(block[#m]))))
#assert(has-marker(list([a], [b #m])))
#assert(has-marker(grid(columns: 2, [a], [#m])))
#assert(has-marker(figure(caption: [c])[#m]))

// text(size: ..)[..] produces a styled element wrapping a text element, not
// a text element itself, so a marker inside it is two levels down.
#assert(has-marker(text(size: 12pt)[#m]))

// [*a* b] is a genuine sequence: adjacent text merges, so [a b] would not be.
#assert(has-marker([*a* #m]))

#assert(not has-marker([plain text]))
#assert(not has-marker(block[nothing here]))
#assert(not has-marker(block(box(block[still nothing]))))
#assert(not has-marker(metadata((tag: "other"))))
#assert(not has-marker([*a* b]))

walk detection tests passed.
