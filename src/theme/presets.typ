///! The built in themes, and the one a deck takes by default.
///!
///! One file so that `lib.typ` imports one, and so that a third preset is one
///! line here rather than a decision about the facade.
///!
///! `theme-default` is `plain`. Specification 5.4 said `banded`, and is amended:
///! a default that draws chrome is a default every deck has to opt out of, and
///! the deck's own `theme: none` path is this same value, so a deck that names
///! no theme and one that names `theme-plain()` are the same deck.

#import "presets/banded.typ": theme-banded
#import "presets/plain.typ": theme-plain

/// The theme a deck renders under when it names none.
///
/// `plain`, so a deck opts into chrome rather than out of it.
/// @category theme
/// @stability experimental
/// @returns dictionary
/// @examples-static
/// ```typst
/// #let base = theme-default()
/// ```
#let theme-default() = theme-plain()
