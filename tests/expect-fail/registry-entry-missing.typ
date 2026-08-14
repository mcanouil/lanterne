// A bucket entry missing its recipe cleared the shape check, because only the
// element function was looked for, and _get then read the recipe anyway. The
// raw Typst error names a key rather than the function that builds a registry.
//
// The expectation stops before the repr of the registry, which is noise here:
// what matters is that the package answers rather than the compiler.
// EXPECT: lookup: registry must be a registry built by register-container;
#import "../../src/core/registry.typ": lookup
#let _ = lookup(block, registry: (repr(block): ((fn: block),)))
