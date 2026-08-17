// EXPECT: step: a heading cannot sit inside a stepped region. Move the heading out of the region, or raise slide-level so it opens a slide of its own.
#import "../../src/core/steps.typ": step
#let _ = step("2", [=== t])
