// EXPECT: split-at: keep must be a function or none; got true.
#import "../../src/core/split.typ": split-at
#import "../../src/core/marker.typ": is-marker
#let _ = split-at([a], is-marker, keep: true)
