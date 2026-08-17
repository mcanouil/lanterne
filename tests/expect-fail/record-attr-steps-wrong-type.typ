// A slide's own steps floor rejects zero, since a range is one based and step
// 0 is no step at all.
// EXPECT: slide-options: steps must be a positive integer or none; got 0.
#import "../../src/core/slides.typ": slide-options
#let _ = slide-options(steps: 0)
