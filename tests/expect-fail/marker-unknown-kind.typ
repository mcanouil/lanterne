// EXPECT: marker: kind must be one of "pause", "slide-options", "slide"; got
// EXPECT: "nope".
#import "../../src/core/marker.typ": marker
#let _ = marker("nope")
