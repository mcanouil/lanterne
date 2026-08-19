// lanterne: themable presentation slides for Typst.
//
// A pure re-export facade: it rebinds names and never defines one.
// Implementation lives under src/.
//
// Only the surface the specification names is re-exported here, and only once
// something public can consume it. A module exporting something this file does
// not is internal on purpose, so adding a name here is a decision about the
// package's public contract rather than a convenience.
//
// `register-container` is exported now that `deck` takes a `registry`, so a
// registry it builds has somewhere to be spent.

#import "src/core/registry.typ": register-container
#import "src/core/slides.typ": appendix, slide, slide-options
#import "src/core/steps.typ": context-slide, dim, focus, only, pause, step, uncover
#import "src/emit/step.typ": emit-step
#import "src/render/deck.typ": deck
#import "src/theme/theme.typ": theme-merge, theme-tokens
