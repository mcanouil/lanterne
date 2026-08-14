// EXPECT: lookup: registry must be a dictionary or none; got 1.
#import "../../src/core/registry.typ": lookup
#let _ = lookup(block, registry: 1)
