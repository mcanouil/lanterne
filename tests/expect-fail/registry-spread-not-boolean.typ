// EXPECT: register-container: spread must be a boolean; got 1.
#import "../../src/core/registry.typ": register-container
#let _ = register-container(block, ("body",), spread: 1)
