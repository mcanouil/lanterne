// EXPECT: register-container: registry must be a dictionary or none; got 1.
#import "../../src/core/registry.typ": register-container
#let _ = register-container(block, ("body",), registry: 1)
