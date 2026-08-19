// EXPECT: marker: kind must be one of "appendix", "pause", "slide-options", "slide", "step", "context-slide"; got "nope".
#import "../../src/core/marker.typ": marker
#let _ = marker("nope")
