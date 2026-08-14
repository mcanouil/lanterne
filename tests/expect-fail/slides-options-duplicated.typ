// Two option sets on one slide leave the reader unable to say which applied, so
// neither does.
// EXPECT: slides: a slide carries 2 slide-options markers. Write one
// EXPECT: slide-options call per slide, immediately after its heading.
#import "../../src/core/slides.typ": slide-options, slides
#let _ = slides([== A
#slide-options(smaller: true)
#slide-options(smaller: false)
body])
