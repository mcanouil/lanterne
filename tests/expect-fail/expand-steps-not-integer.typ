// EXPECT: expand: steps must be a positive integer or none; got 0.
#import "../../src/core/expand.typ": expand
#let _ = expand([a], body => body, steps: 0)
