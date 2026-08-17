// EXPECT: expand: a "slide" marker reached step resolution.
#import "../../src/core/expand.typ": expand
#import "../../src/core/slides.typ": slide
#let _ = expand([#block[#slide[x]]], body => body)
