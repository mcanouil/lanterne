// EXPECT: collect: max-depth must be a positive integer; got 0.
#import "../../src/core/walk.typ": collect
#let _ = collect([a], node => false, max-depth: 0)
