// EXPECT: step: before must be one of "visible", "hidden", "dimmed", "removed"; got "faded".
#import "../../src/core/steps.typ": step
#let _ = step("2", [x], before: "faded")
