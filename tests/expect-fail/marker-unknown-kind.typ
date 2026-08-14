// EXPECT: marker: kind must be one of "pause", "slide-options"; got "nope".
#import "../../src/core/marker.typ": marker
#let _ = marker("nope")
