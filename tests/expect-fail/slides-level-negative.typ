// 0 disables heading splitting, and nothing lies below that.
// EXPECT: slides: slide-level must be a non-negative integer; got -1.
#import "../../src/core/slides.typ": slides
#let _ = slides([a], slide-level: -1)
