// EXPECT: register-container: positional must be an array of field names; got 1.
#import "../../src/core/registry.typ": register-container
#let _ = register-container(block, 1)
