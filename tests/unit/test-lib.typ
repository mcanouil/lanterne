// The facade re-exports and never re-implements.
//
// A name reached through lib.typ is asserted to be the same value as the one
// its module exports, so a second implementation cannot appear behind the
// public name without this failing. Compiling the import alone would prove
// only that something of that name exists.

#import "../../lib.typ"
#import "../../src/core/registry.typ"
#import "../../src/core/slides.typ"
#import "../../src/core/steps.typ"
#import "../../src/emit/step.typ"
#import "../../src/render/deck.typ"
#import "../../src/theme/presets.typ"
#import "../../src/theme/theme.typ"

#assert.eq(lib.theme-tokens, theme.theme-tokens)
#assert.eq(lib.theme-default, presets.theme-default)
#assert.eq(lib.theme-plain, presets.theme-plain)
#assert.eq(lib.theme-banded, presets.theme-banded)
#assert.eq(lib.theme-merge, theme.theme-merge)
#assert.eq(lib.deck, deck.deck)
#assert.eq(lib.appendix, slides.appendix)
#assert.eq(lib.slide, slides.slide)
#assert.eq(lib.slide-options, slides.slide-options)
#assert.eq(lib.register-container, registry.register-container)
#assert.eq(lib.context-slide, steps.context-slide)
#assert.eq(lib.dim, steps.dim)
#assert.eq(lib.focus, steps.focus)
#assert.eq(lib.only, steps.only)
#assert.eq(lib.pause, steps.pause)
#assert.eq(lib.step, steps.step)
#assert.eq(lib.uncover, steps.uncover)
#assert.eq(lib.emit-step, step.emit-step)

// The surface is what the package promises and no more. A module exporting
// something absent here is internal on purpose: `lookup`, `has-marker`,
// `rebuild`, `split-on` and `check-token` are all reachable from src/ and none
// of them is public.
//
// `slides` is absent: a deck is split by `deck`, and calling the splitter
// directly buys records nothing public consumes.
#assert.eq(
  dictionary(lib).keys().sorted(),
  (
    "appendix", "context-slide", "deck", "dim", "emit-step", "focus", "only",
    "pause", "register-container", "slide", "slide-options", "step",
    "theme-banded", "theme-default", "theme-merge", "theme-plain",
    "theme-tokens", "uncover",
  ),
)

// The facade is used as a wildcard import, which is the form every deck and
// every example takes.
#import "../../lib.typ": *
#assert.eq(theme-tokens().bg, white)
#assert.eq(theme-merge(theme-tokens(), (margin: 1cm)).margin, 1cm)
#assert.eq(theme-default(), theme-plain())

lib tests passed.
