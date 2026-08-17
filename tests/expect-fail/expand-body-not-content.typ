// EXPECT: expand: body must be content; got "a".
#import "../../src/core/expand.typ": expand
#let _ = expand("a", body => body)
