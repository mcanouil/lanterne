// The facade re-exports and never re-implements.
//
// A name reached through lib.typ is asserted to be the same value as the one
// its module exports, so a second implementation cannot appear behind the
// public name without this failing. Compiling the import alone would prove
// only that something of that name exists.

#import "../../lib.typ"
#import "../../src/core/slides.typ"
#import "../../src/render/deck.typ"
#import "../../src/theme/theme.typ"

#assert.eq(lib.theme-tokens, theme.theme-tokens)
#assert.eq(lib.theme-merge, theme.theme-merge)
#assert.eq(lib.deck, deck.deck)
#assert.eq(lib.slide, slides.slide)
#assert.eq(lib.slide-options, slides.slide-options)

// The surface is what the package promises and no more. A module exporting
// something absent here is internal on purpose: `lookup`, `has-marker`,
// `rebuild`, `split-on` and `check-token` are all reachable from src/ and none
// of them is public.
//
// `register-container` is absent for a sharper reason than the rest. It builds
// a registry value, and `rebuild` is the only function that reads one, so
// exporting it would promise a capability with no public way to spend it. It
// arrives with the deck option that takes a registry.
//
// `slides` is absent as well: a deck is split by `deck`, and calling the
// splitter directly buys records nothing public consumes.
#assert.eq(
  dictionary(lib).keys().sorted(),
  ("deck", "slide", "slide-options", "theme-merge", "theme-tokens"),
)

// The facade is used as a wildcard import, which is the form every deck and
// every example takes.
#import "../../lib.typ": *
#assert.eq(theme-tokens().bg, white)
#assert.eq(theme-merge(theme-tokens(), (margin: 1cm)).margin, 1cm)

lib tests passed.
