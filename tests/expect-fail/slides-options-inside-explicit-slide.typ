// An explicit slide takes its options as arguments, so a marker inside its body
// has no heading to follow and would be read by nobody. It renders as nothing,
// so the deck would otherwise build with the option silently lost.
// EXPECT: slides: slide-options was written inside an explicit slide. Pass the
// EXPECT: option to slide itself, as slide(smaller: true)[...].
#import "../../src/core/slides.typ": slide, slide-options, slides
#let _ = slides([#slide(title: [T])[#slide-options(smaller: true) inside]])
