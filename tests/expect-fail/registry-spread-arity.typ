// Spread applies to a container whose one field holds an array, so more than
// one positional field is a contradiction rather than a type error.
// EXPECT: register-container: spread needs exactly one positional field; got
// EXPECT: ("a", "b"). Spread applies to a container whose one field holds an
// EXPECT: array.
#import "../../src/core/registry.typ": register-container
#let _ = register-container(block, ("a", "b"), spread: true)
