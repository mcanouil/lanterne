// EXPECT: slides: slide-level must be a non-negative integer; got 2.5.
#import "../../src/core/slides.typ": slides
#let _ = slides([a], slide-level: 2.5)
