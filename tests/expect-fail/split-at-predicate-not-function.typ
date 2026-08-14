// EXPECT: split-at: predicate must be a function; got "not a function".
#import "../../src/core/split.typ": split-at
#let _ = split-at([a], "not a function")
