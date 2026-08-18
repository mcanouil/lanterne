// EXPECT: rebuild: match must be a function; got "marker".
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild([a], node => node, match: "marker")
