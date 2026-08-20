// EXPECT: split-head: body must be content; got "a".
#import "../../src/core/split.typ": split-head
#let _ = split-head("a", node => true)
