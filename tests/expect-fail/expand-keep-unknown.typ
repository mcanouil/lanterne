// EXPECT: expand: keep must be none, "final", or an array of spans; got "last".
#import "../../src/core/expand.typ": expand
#let _ = expand([a], body => body, keep: "last")
