// A partial base would flow downstream and fail where it is read, naming a
// missing key, rather than here, naming the theme that lacks it.
// EXPECT: theme-merge: base is missing "fg", "accent", "accent-fg", "muted", "border",
// EXPECT: "dim-opacity", "font-base", "font-heading", "size-base", "scale-ratio",
// EXPECT: "weight-heading", "leading", "margin", "gutter", "header-height",
// EXPECT: "footer-height", "stroke-width", "extra", "slots". Build a base with
// EXPECT: theme-tokens rather than by hand.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-merge((bg: white), (:))
