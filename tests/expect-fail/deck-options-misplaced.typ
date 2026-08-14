// The split reports under the name the author called, so a deck's own author is
// told about `deck` rather than about a splitter they never invoked.
// EXPECT: deck: slide-options must come before the slide's content. Move the
// EXPECT: slide-options call to just after the heading.
#import "../../src/core/slides.typ": slide-options
#import "../../src/render/deck.typ": deck
#let _ = deck([== A

body

#slide-options(smaller: true)])
