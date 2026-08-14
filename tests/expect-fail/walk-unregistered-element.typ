// The loudest guarantee the package makes: an element carrying a step marker
// that cannot be reconstructed fails the build rather than silently losing the
// marker. A deck that lost a step boundary is worse than one that did not
// compile, so there is no degrade path and nothing to configure.
//
// `outline` is the element used because it is unregistered and holds content in
// a field, which tests/unit/test-registry.typ pins.
//
// The hint names `register-container`, which is not exported from lib.typ
// today. Neither is `rebuild`, so this panic is unreachable from outside the
// package: the two become public together with the deck function that takes a
// registry.
// EXPECT: rebuild: cannot reconstruct element outline with fields ("title",)
// EXPECT: containing a step marker. Register it with register-container(fn,
// EXPECT: positional).
#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild(outline(title: [#marker(MARKER-PAUSE)]), node => [])
