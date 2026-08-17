// EXPECT: slide-options: slide option must be one of "smaller", "steps"; got
// EXPECT: "smallr".
#import "../../src/core/slides.typ": slide-options
#let _ = slide-options(smallr: true)
