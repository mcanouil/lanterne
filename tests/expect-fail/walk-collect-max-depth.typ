// EXPECT: collect-markers: max-depth must be a positive integer; got 0.
#import "../../src/core/walk.typ": collect-markers
#let _ = collect-markers([a], max-depth: 0)
