split-body-not-content.typ
// EXPECT: split-on: body must be content; got "a".
#import "../../src/core/split.typ": split-on
#import "../../src/core/marker.typ": is-marker
#let _ = split-on("a", is-marker)
