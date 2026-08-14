// A positional argument carries no option name to validate against, so it is
// rejected rather than ignored.
// EXPECT: slide-options: takes named arguments only; got
#import "../../src/core/slides.typ": slide-options
#let _ = slide-options(true)
