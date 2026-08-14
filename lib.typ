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
// `register-container` is deliberately absent. It builds a registry value, and
// the only function that reads one is `rebuild`, which is internal, so the
// export would hand a user something with nowhere to put it. It arrives with
// the deck function that takes a registry.

#import "src/theme/theme.typ": theme-merge, theme-tokens
