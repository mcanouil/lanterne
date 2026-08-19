// EXPECT: slides: an appendix marker sits inside an element, where the split
// EXPECT: cannot reach it. Write #appendix as a top level child of the document
// EXPECT: body.
#import "../../src/core/slides.typ": appendix, slides
#let _ = slides([== A
#block[#appendix]

== B])
