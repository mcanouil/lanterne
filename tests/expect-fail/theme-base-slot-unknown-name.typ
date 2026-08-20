// The base half of the same guard. The message says `base.slots` rather than
// `slots`, because a base that did not come from theme-tokens is the one case
// this re-validation exists to serve, and the author needs to know the bad key
// is in the theme they were handed rather than in the overrides they just
// wrote.
// EXPECT: theme-merge: base.slots key must be one of "render-title-slide",
// EXPECT: "render-section-slide", "render-header", "render-footer",
// EXPECT: "render-progress"; got "render-headr". The set of five is fixed.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let base = { let b = theme-tokens(); b.insert("slots", (render-headr: () => [])); b }
#let _ = theme-merge(base, (:))
