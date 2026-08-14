// The marker renders as nothing, so a call the splitter does not recognise
// costs the slide its options and builds a deck that is quietly wrong.
// EXPECT: slides: slide-options must come before the slide's content. Move the
// EXPECT: slide-options call to just after the heading.
#import "../../src/core/slides.typ": slide-options, slides
#let _ = slides([== A
body
#slide-options(smaller: true)])
