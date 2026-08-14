// lanterne: themable presentation slides for Typst.
//
// A pure re-export facade: it rebinds names and never defines one.
// Implementation lives under src/.
//
// Only the surface the specification names is re-exported here. A module
// exporting something this file does not is internal on purpose, so adding a
// name to this file is a decision about the package's public contract rather
// than a convenience.

#import "src/core/registry.typ": register-container
#import "src/theme/theme.typ": theme-merge, theme-tokens
