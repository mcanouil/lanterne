// Both public splitters validate their arguments, and each reports under its
// own name: a message naming a function the author never called sends them to
// the wrong line.
// EXPECT: split-at: body must be content; got "a".
#import "../../src/core/split.typ": split-at
#import "../../src/core/marker.typ": is-marker
#let _ = split-at("a", is-marker)
