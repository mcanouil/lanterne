// A theme is a validated token dictionary. Two functions build one, and
// nothing else may, so every token dictionary the package handles has been
// through the same per-key validation and no code downstream re-checks what it
// reads.
//
// Typst cannot catch a panic, so the rejecting paths are recorded verbatim at
// the foot of this file from a throwaway compile.

#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#import "../../src/theme/tokens.typ": default-tokens

// With no overrides, a theme is the defaults.
#assert.eq(theme-tokens(), default-tokens())

// An override replaces one key and leaves every other at its default. The key
// set is asserted alongside, because a merge that dropped a key would satisfy
// the value assertions and fail at the point of use a milestone later.
#let dark = theme-tokens(bg: black, fg: white)
#assert.eq(dark.bg, black)
#assert.eq(dark.fg, white)
#assert.eq(dark.size-base, default-tokens().size-base)
#assert.eq(dark.keys().sorted(), default-tokens().keys().sorted())

// The defaults are untouched by a theme built from them.
#assert.eq(default-tokens().bg, white)

// `extra` takes any keys, and its contents are not validated: a value that
// would be rejected under every canonical rule is kept as it is.
#let custom = theme-tokens(extra: (badge-fill: red, badge-width: 3))
#assert.eq(custom.extra.badge-fill, red)
#assert.eq(custom.extra.badge-width, 3)

// Merging is additive over `extra` rather than replacing it. Replacing would
// mean setting one token of your own silently dropped every other the base
// theme carried, which is the failure a theme author would notice last.
#let merged = theme-merge(custom, (extra: (badge-width: 5, badge-radius: 2pt)))
#assert.eq(merged.extra.badge-fill, red)
#assert.eq(merged.extra.badge-width, 5)
#assert.eq(merged.extra.badge-radius, 2pt)

// A canonical token still validates when it arrives through a merge rather
// than through the constructor.
#assert.eq(theme-merge(theme-tokens(), (margin: 1cm)).margin, 1cm)

// Merging nothing changes nothing.
#assert.eq(theme-merge(dark, (:)), dark)

// The result of a merge is itself a valid base, so merges chain and the last
// writer wins.
#assert.eq(theme-merge(theme-merge(dark, (margin: 1cm)), (margin: 3cm)).margin, 3cm)
#assert.eq(theme-merge(theme-merge(dark, (margin: 1cm)), (margin: 3cm)).bg, black)

// The rejecting paths, compiled by hand from .scratch/theme-probe.typ and
// recorded verbatim. The scope in each is the function the author called, not
// the private helper both route through, which is the whole reason that helper
// takes a scope rather than naming itself.
//
//   theme-tokens(white)
//     theme-tokens: takes named arguments only; got (luma(100%),). Write
//     theme-tokens(bg: white).
//
//   theme-tokens(bgg: white)
//     theme-tokens: token name must be one of "bg", "fg", "dim-opacity",
//     "font-base", "font-heading", "size-base", "scale-ratio",
//     "weight-heading", "leading", "margin"; got "bgg". A token of your own
//     belongs in extra.
//
//   theme-merge(theme-tokens(), (bgg: 1))
//     the same message, under scope `theme-merge`.
//
//   theme-tokens(margin: 1)
//     theme-tokens: margin must be a length; got 1.
//
//   theme-merge((bg: white), (:))
//     theme-merge: base is missing "fg", "dim-opacity", "font-base",
//     "font-heading", "size-base", "scale-ratio", "weight-heading", "leading",
//     "margin", "extra". Build a base with theme-tokens rather than by hand.
//
//   theme-tokens(extra: 1)
//     theme-tokens: extra must be a dictionary; got 1.

theme tests passed.
