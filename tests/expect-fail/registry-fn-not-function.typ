// EXPECT: register-container: fn must be a function; got 1.
#import "../../src/core/registry.typ": register-container
#let _ = register-container(1, ("body",))
