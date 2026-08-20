// Both halves are validated, not only the one this render selects. A deck built
// in light mode would otherwise carry a dark half nobody had checked, and the
// mistake would surface for whoever first rendered it the other way.
// EXPECT: theme: token name must be one of "bg", "fg", "accent", "accent-fg",
// EXPECT: "muted", "border", "dim-opacity", "font-base", "font-heading",
// EXPECT: "size-base", "scale-ratio", "weight-heading", "leading", "margin",
// EXPECT: "gutter", "header-height", "footer-height", "stroke-width"; got "bgg".
// EXPECT: A token of your own belongs in extra.
#import "../../src/theme/theme.typ": resolve-mode, theme-tokens
#let dark = { let d = theme-tokens(); d.insert("bgg", white); d }
#let _ = resolve-mode((light: theme-tokens(), dark: dark), "light", "theme")
