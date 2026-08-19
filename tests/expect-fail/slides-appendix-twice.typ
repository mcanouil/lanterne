// EXPECT: slides: a deck carries 2 appendix markers. Write one #appendix, at
// EXPECT: the point the appendix opens.
#import "../../src/core/slides.typ": appendix, slides
#let _ = slides([== A
#appendix

== B
#appendix

== C])
