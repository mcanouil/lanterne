// EXPECT: increments: body must be content; got "a".
#import "../../src/core/counters.typ": increments
#let _ = increments("a")
