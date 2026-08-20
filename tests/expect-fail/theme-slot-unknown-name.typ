// The five renderer slots are a frozen contract, so a mistyped one is refused
// rather than stored as a renderer nothing will ever call.
// EXPECT: theme-tokens: slots key must be one of "render-title-slide",
// EXPECT: "render-section-slide", "render-header", "render-footer",
// EXPECT: "render-progress"; got "render-headr". The set of five is fixed.
#import "../../src/theme/theme.typ": theme-tokens
#let _ = theme-tokens(slots: (render-headr: (info: none, tokens: none, state: none) => []))
