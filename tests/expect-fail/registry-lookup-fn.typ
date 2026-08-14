// EXPECT: lookup: fn must be a function; got 1.
#import "../../src/core/registry.typ": lookup
#let _ = lookup(1)
