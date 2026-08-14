// EXPECT: rebuild: transform must be a function; got "x".
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild([a], "x")
