// EXPECT: step: body must be content; got "x".
#import "../../src/core/steps.typ": step
#let _ = step("2", "x")
