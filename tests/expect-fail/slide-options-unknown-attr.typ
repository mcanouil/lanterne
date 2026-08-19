// EXPECT: slide-options: slide option must be one of "appendix", "smaller", "steps"; got
// EXPECT: "smallr".
#import "../../src/core/slides.typ": slide-options
#let _ = slide-options(smallr: true)
