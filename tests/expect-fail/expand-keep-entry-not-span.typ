// EXPECT: expand: a keep entry must be a span from parse-range, a dictionary carrying from and to; got 1.
#import "../../src/core/expand.typ": expand
#let _ = expand([a], body => body, keep: (1, 2))
