split-predicate-not-function.typ
// EXPECT: split-on: predicate must be a function; got "not a function".
#import "../../src/core/split.typ": split-on
#let _ = split-on([a], "not a function")
