// EXPECT: collect: predicate must be a function; got "figure".
#import "../../src/core/walk.typ": collect
#let _ = collect([a], "figure")
