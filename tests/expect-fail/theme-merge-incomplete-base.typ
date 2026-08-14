theme-merge-incomplete-base.typ
// A partial base would flow downstream and fail where it is read, naming a
// missing key, rather than here, naming the theme that lacks it.
// EXPECT: theme-merge: base is missing "fg", "dim-opacity", "font-base",
// EXPECT: "font-heading", "size-base", "scale-ratio", "weight-heading",
// EXPECT: "leading", "margin", "extra". Build a base with theme-tokens rather
// EXPECT: than by hand.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-merge((bg: white), (:))
