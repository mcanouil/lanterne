// EXPECT: register-container: positional entry must be a string; got 1.
#import "../../src/core/registry.typ": register-container
#let _ = register-container(block, (1,))
