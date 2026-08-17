// EXPECT: context-slide: fn must be a function taking the step index and total; got [x].
#import "../../src/core/steps.typ": context-slide
#let _ = context-slide([x])
