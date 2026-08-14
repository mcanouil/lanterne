// EXPECT: has-marker: max-depth must be a positive integer; got 0.
#import "../../src/core/walk.typ": has-marker
#let _ = has-marker([a], max-depth: 0)
