///! The preset that draws nothing.
///!
///! `plain` is the canonical token defaults and no renderers at all, so a slide
///! under it is its title and its body on a page dressed by the theme's
///! geometry, fills and fonts.
///!
///! It is what a deck naming no theme renders under, so the two are the same
///! value rather than two values that agree today. `tests/unit/test-presets.typ`
///! asserts that directly; the visual goldens corroborate it, and cannot carry
///! it alone, since two dictionaries can render alike and differ.

#import "../theme.typ": theme-tokens

/// The plain theme: the canonical defaults, with no renderers.
///
/// A theme that draws chrome is a theme every deck would have to opt out of, so
/// the default draws none. `theme-banded` is the one that composes a page, and
/// specification 5.4 is amended to say which of the two is the default.
/// @category theme
/// @stability experimental
/// @param ..overrides The tokens to set, named only, as `theme-tokens` takes them.
/// @returns dictionary
/// @examples-static
/// ```typst
/// #show: deck.with(theme: theme-plain(bg: rgb("#fbfbfd")))
/// ```
#let theme-plain(..overrides) = theme-tokens(..overrides)
