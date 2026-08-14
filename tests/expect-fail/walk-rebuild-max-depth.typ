// EXPECT: rebuild: max-depth must be a positive integer; got 0.
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild([a], node => node, max-depth: 0)
