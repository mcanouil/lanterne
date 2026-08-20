// EXPECT: split-head: predicate must be a function; got "not a function".
#import "../../src/core/split.typ": split-head
#let _ = split-head([a], "not a function")
